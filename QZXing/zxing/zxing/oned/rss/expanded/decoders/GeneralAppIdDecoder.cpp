#include "GeneralAppIdDecoder.h"
#include <zxing/common/StringUtils.h>

namespace zxing {
namespace oned {
namespace rss {

GeneralAppIdDecoder::GeneralAppIdDecoder(Ref<BitArray> information)
    : m_information(information),
      m_buffer("")
{

}

String GeneralAppIdDecoder::decodeAllCodes(String &buff, int initialPosition)
{
    int currentPosition = initialPosition;
    String remaining("");
    do {
        DecodedInformation info(decodeGeneralPurposeField(currentPosition, remaining));
        String parsedFields = FieldParser::parseFieldsInGeneralPurpose(info.getNewString());
        if (parsedFields.length() > 0) {
            buff.append(parsedFields.getText());
        }
        if (info.isRemaining()) {
            remaining = String(common::StringUtils::intToStr(info.getRemainingValue()));
        } else {
            remaining = String("");
        }

        if (currentPosition == info.getNewPosition()) { // No step forward!
            break;
        }
        currentPosition = info.getNewPosition();
    } while (true);

    return buff;
}

bool GeneralAppIdDecoder::isStillNumeric(int pos) const
{
    // It's numeric if it still has 7 positions
    // and one of the first 4 bits is "1".
    if (pos + 7 > m_information->getSize()) {
        return pos + 4 <= m_information->getSize();
    }

    for (int i = pos; i < pos + 3; ++i) {
        if (m_information->get(i)) {
            return true;
        }
    }

    return m_information->get(pos + 3);
}

DecodedNumeric* GeneralAppIdDecoder::decodeNumeric(int pos)
{
    if (pos + 7 > m_information->getSize()) {
        int numeric = extractNumericValueFromBitArray(pos, 4);
        if (numeric == 0) {
            return new DecodedNumeric(m_information->getSize(), DecodedNumeric::FNC1, DecodedNumeric::FNC1);
        }
        return new DecodedNumeric(m_information->getSize(), numeric - 1, DecodedNumeric::FNC1);
    }
    int numeric = extractNumericValueFromBitArray(pos, 7);

    int digit1  = (numeric - 8) / 11;
    int digit2  = (numeric - 8) % 11;

    return new DecodedNumeric(pos + 7, digit1, digit2);
}

int GeneralAppIdDecoder::extractNumericValueFromBitArray(int pos, int bits)
{
    return extractNumericValueFromBitArray(m_information, pos, bits);
}

int GeneralAppIdDecoder::extractNumericValueFromBitArray(Ref<BitArray> information, int pos, int bits)
{
    int value = 0;
    for (int i = 0; i < bits; ++i) {
        if (information->get(pos + i)) {
            value |= 1 << (bits - i - 1);
        }
    }

    return value;
}

DecodedInformation GeneralAppIdDecoder::decodeGeneralPurposeField(int pos, String &remaining)
{
    m_buffer = String("");

    if (remaining.length() > 0) {
        m_buffer.append(remaining.getText());
    }

    m_current.setPosition(pos);

    DecodedInformation lastDecoded(parseBlocks());
    if (lastDecoded.getNewString().length() > 0 && lastDecoded.isRemaining()) {
        return DecodedInformation(m_current.getPosition(), m_buffer, lastDecoded.getRemainingValue());
    }
    return DecodedInformation(m_current.getPosition(), m_buffer);
}

DecodedInformation GeneralAppIdDecoder::parseBlocks()
{
    bool isFinished;
    BlockParsedResult* result;
    do {
        int initialPosition = m_current.getPosition();

        if (m_current.isAlpha()) {
            result = parseAlphaBlock();
            isFinished = result->isFinished();
        } else if (m_current.isIsoIec646()) {
            result = parseIsoIec646Block();
            isFinished = result->isFinished();
        } else { // it must be numeric
            result = parseNumericBlock();
            isFinished = result->isFinished();
        }

        bool positionChanged = initialPosition != m_current.getPosition();
        if (!positionChanged && !isFinished) {
            break;
        }
    } while (!isFinished);

    return result->getDecodedInformation();
}

BlockParsedResult* GeneralAppIdDecoder::parseNumericBlock()
{
    while (isStillNumeric(m_current.getPosition())) {
        DecodedNumeric numeric(decodeNumeric(m_current.getPosition()));
        m_current.setPosition(numeric.getNewPosition());

        if (numeric.isFirstDigitFNC1()) {
            DecodedInformation information(0, String(""));
            if (numeric.isSecondDigitFNC1()) {
                return new BlockParsedResult(DecodedInformation(m_current.getPosition(), m_buffer), true);
            } else {
                return new BlockParsedResult(DecodedInformation(m_current.getPosition(), m_buffer, numeric.getSecondDigit()), true);
            }
        }
        m_buffer.append(common::StringUtils::intToStr(numeric.getFirstDigit()));

        if (numeric.isSecondDigitFNC1()) {
            DecodedInformation information(m_current.getPosition(), m_buffer);
            return new BlockParsedResult(information, true);
        }
        m_buffer.append(common::StringUtils::intToStr(numeric.getSecondDigit()));
    }

    if (isNumericToAlphaNumericLatch(m_current.getPosition())) {
        m_current.setAlpha();
        m_current.incrementPosition(4);
    }
    return new BlockParsedResult(false);
}

BlockParsedResult* GeneralAppIdDecoder::parseIsoIec646Block()
{
    while (isStillIsoIec646(m_current.getPosition())) {
        DecodedChar iso = decodeIsoIec646(m_current.getPosition());
        m_current.setPosition(iso.getNewPosition());

        if (iso.isFNC1()) {
            DecodedInformation information(m_current.getPosition(), m_buffer);
            return new BlockParsedResult(information, true);
        }
        m_buffer.append(iso.getValue());
    }

    if (isAlphaOr646ToNumericLatch(m_current.getPosition())) {
        m_current.incrementPosition(3);
        m_current.setNumeric();
    } else if (isAlphaTo646ToAlphaLatch(m_current.getPosition())) {
        if (m_current.getPosition() + 5 < m_information->getSize()) {
            m_current.incrementPosition(5);
        } else {
            m_current.setPosition(m_information->getSize());
        }

        m_current.setAlpha();
    }
    return new BlockParsedResult(false);
}

BlockParsedResult* GeneralAppIdDecoder::parseAlphaBlock()
{
    while (isStillAlpha(m_current.getPosition())) {
        DecodedChar alpha(decodeAlphanumeric(m_current.getPosition()));
        m_current.setPosition(alpha.getNewPosition());

        if (alpha.isFNC1()) {
            DecodedInformation information(m_current.getPosition(), m_buffer);
            return new BlockParsedResult(information, true); //end of the char block
        }

        m_buffer.append(alpha.getValue());
    }

    if (isAlphaOr646ToNumericLatch(m_current.getPosition())) {
        m_current.incrementPosition(3);
        m_current.setNumeric();
    } else if (isAlphaTo646ToAlphaLatch(m_current.getPosition())) {
        if (m_current.getPosition() + 5 < m_information->getSize()) {
            m_current.incrementPosition(5);
        } else {
            m_current.setPosition(m_information->getSize());
        }

        m_current.setIsoIec646();
    }
    return new BlockParsedResult(false);
}

bool GeneralAppIdDecoder::isStillIsoIec646(int pos)
{
    if (pos + 5 > m_information->getSize()) {
        return false;
    }

    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue >= 5 && fiveBitValue < 16) {
        return true;
    }

    if (pos + 7 > m_information->getSize()) {
        return false;
    }

    int sevenBitValue = extractNumericValueFromBitArray(pos, 7);
    if (sevenBitValue >= 64 && sevenBitValue < 116) {
        return true;
    }

    if (pos + 8 > m_information->getSize()) {
        return false;
    }

    int eightBitValue = extractNumericValueFromBitArray(pos, 8);
    return eightBitValue >= 232 && eightBitValue < 253;
}

DecodedChar GeneralAppIdDecoder::decodeIsoIec646(int pos)
{
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue == 15) {
        return DecodedChar(pos + 5, DecodedChar::FNC1);
    }

    if (fiveBitValue >= 5 && fiveBitValue < 15) {
        return DecodedChar(pos + 5, static_cast<char>('0' + fiveBitValue - 5));
    }

    int sevenBitValue = extractNumericValueFromBitArray(pos, 7);

    if (sevenBitValue >= 64 && sevenBitValue < 90) {
        return DecodedChar(pos + 7, static_cast<char>(sevenBitValue + 1));
    }

    if (sevenBitValue >= 90 && sevenBitValue < 116) {
        return DecodedChar(pos + 7, static_cast<char>(sevenBitValue + 7));
    }

    int eightBitValue = extractNumericValueFromBitArray(pos, 8);
    char c;
    switch (eightBitValue) {
    case 232:
        c = '!';
        break;
    case 233:
        c = '"';
        break;
    case 234:
        c = '%';
        break;
    case 235:
        c = '&';
        break;
    case 236:
        c = '\'';
        break;
    case 237:
        c = '(';
        break;
    case 238:
        c = ')';
        break;
    case 239:
        c = '*';
        break;
    case 240:
        c = '+';
        break;
    case 241:
        c = ',';
        break;
    case 242:
        c = '-';
        break;
    case 243:
        c = '.';
        break;
    case 244:
        c = '/';
        break;
    case 245:
        c = ':';
        break;
    case 246:
        c = ';';
        break;
    case 247:
        c = '<';
        break;
    case 248:
        c = '=';
        break;
    case 249:
        c = '>';
        break;
    case 250:
        c = '?';
        break;
    case 251:
        c = '_';
        break;
    case 252:
        c = ' ';
        break;
    default:
        throw FormatException::getFormatInstance();
    }
    return DecodedChar(pos + 8, c);
}

bool GeneralAppIdDecoder::isStillAlpha(int pos)
{
    if (pos + 5 > m_information->getSize()) {
        return false;
    }

    // We now check if it's a valid 5-bit value (0..9 and FNC1)
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue >= 5 && fiveBitValue < 16) {
        return true;
    }

    if (pos + 6 > m_information->getSize()) {
        return false;
    }

    int sixBitValue =  extractNumericValueFromBitArray(pos, 6);
    return sixBitValue >= 16 && sixBitValue < 63; // 63 not included
}

DecodedChar GeneralAppIdDecoder::decodeAlphanumeric(int pos)
{
    int fiveBitValue = extractNumericValueFromBitArray(pos, 5);
    if (fiveBitValue == 15) {
        return DecodedChar(pos + 5, DecodedChar::FNC1);
    }

    if (fiveBitValue >= 5 && fiveBitValue < 15) {
        return DecodedChar(pos + 5, static_cast<char>('0' + fiveBitValue - 5));
    }

    int sixBitValue =  extractNumericValueFromBitArray(pos, 6);

    if (sixBitValue >= 32 && sixBitValue < 58) {
        return DecodedChar(pos + 6, static_cast<char>(sixBitValue + 33));
    }

    char c;
    switch (sixBitValue) {
    case 58:
        c = '*';
        break;
    case 59:
        c = ',';
        break;
    case 60:
        c = '-';
        break;
    case 61:
        c = '.';
        break;
    case 62:
        c = '/';
        break;
    default:
    {
        std::string msg = "Decoding invalid alphanumeric value: " + common::StringUtils::intToStr(sixBitValue);
        throw IllegalStateException(msg.c_str());
    }
    }
    return DecodedChar(pos + 6, c);
}

bool GeneralAppIdDecoder::isAlphaTo646ToAlphaLatch(int pos)
{
    if (pos + 1 > m_information->getSize()) {
        return false;
    }

    for (int i = 0; i < 5 && i + pos < m_information->getSize(); ++i) {
        if (i == 2) {
            if (!m_information->get(pos + 2)) {
                return false;
            }
        } else if (m_information->get(pos + i)) {
            return false;
        }
    }

    return true;
}

bool GeneralAppIdDecoder::isAlphaOr646ToNumericLatch(int pos)
{
    // Next is alphanumeric if there are 3 positions and they are all zeros
    if (pos + 3 > m_information->getSize()) {
        return false;
    }

    for (int i = pos; i < pos + 3; ++i) {
        if (m_information->get(i)) {
            return false;
        }
    }
    return true;
}

bool GeneralAppIdDecoder::isNumericToAlphaNumericLatch(int pos) {
    // Next is alphanumeric if there are 4 positions and they are all zeros, or
    // if there is a subset of this just before the end of the symbol
    if (pos + 1 > m_information->getSize()) {
        return false;
    }

    for (int i = 0; i < 4 && i + pos < m_information->getSize(); ++i) {
        if (m_information->get(pos + i)) {
            return false;
        }
    }
    return true;
}

}
}
}
