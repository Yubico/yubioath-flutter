#include "FieldParser.h"

#include <algorithm>

namespace zxing {
namespace oned {
namespace rss {

static const int VARIABLE_LENGTH = 99999;

struct DigitData {
    std::string digit;
    int variableLength;
    int length;
};

static const DigitData TWO_DIGIT_DATA_LENGTH[] {
  // "DIGITS", new Integer(LENGTH)
  //    or
  // "DIGITS", VARIABLE_LENGTH, new Integer(MAX_SIZE)

  { "00", 18, 0},
  { "01", 14, 0},
  { "02", 14, 0},

  { "10", VARIABLE_LENGTH, 20},
  { "11", 6, 0},
  { "12", 6, 0},
  { "13", 6, 0},
  { "15", 6, 0},
  { "17", 6, 0},

  { "20", 2, 0},
  { "21", VARIABLE_LENGTH, 20},
  { "22", VARIABLE_LENGTH, 29},

  { "30", VARIABLE_LENGTH, 8},
  { "37", VARIABLE_LENGTH, 8},

  //internal company codes
  { "90", VARIABLE_LENGTH, 30},
  { "91", VARIABLE_LENGTH, 30},
  { "92", VARIABLE_LENGTH, 30},
  { "93", VARIABLE_LENGTH, 30},
  { "94", VARIABLE_LENGTH, 30},
  { "95", VARIABLE_LENGTH, 30},
  { "96", VARIABLE_LENGTH, 30},
  { "97", VARIABLE_LENGTH, 30},
  { "98", VARIABLE_LENGTH, 30},
  { "99", VARIABLE_LENGTH, 30},
};

static const DigitData THREE_DIGIT_DATA_LENGTH[] {
  // Same format as above

  { "240", VARIABLE_LENGTH, 30},
  { "241", VARIABLE_LENGTH, 30},
  { "242", VARIABLE_LENGTH, 6},
  { "250", VARIABLE_LENGTH, 30},
  { "251", VARIABLE_LENGTH, 30},
  { "253", VARIABLE_LENGTH, 17},
  { "254", VARIABLE_LENGTH, 20},

  { "400", VARIABLE_LENGTH, 30},
  { "401", VARIABLE_LENGTH, 30},
  { "402", 17, 0},
  { "403", VARIABLE_LENGTH, 30},
  { "410", 13, 0},
  { "411", 13, 0},
  { "412", 13, 0},
  { "413", 13, 0},
  { "414", 13, 0},
  { "420", VARIABLE_LENGTH, 20},
  { "421", VARIABLE_LENGTH, 15},
  { "422", 3, 0},
  { "423", VARIABLE_LENGTH, 15},
  { "424", 3, 0},
  { "425", 3, 0},
  { "426", 3, 0},
};

static const DigitData THREE_DIGIT_PLUS_DIGIT_DATA_LENGTH[] {
  // Same format as above

  { "310", 6, 0},
  { "311", 6, 0},
  { "312", 6, 0},
  { "313", 6, 0},
  { "314", 6, 0},
  { "315", 6, 0},
  { "316", 6, 0},
  { "320", 6, 0},
  { "321", 6, 0},
  { "322", 6, 0},
  { "323", 6, 0},
  { "324", 6, 0},
  { "325", 6, 0},
  { "326", 6, 0},
  { "327", 6, 0},
  { "328", 6, 0},
  { "329", 6, 0},
  { "330", 6, 0},
  { "331", 6, 0},
  { "332", 6, 0},
  { "333", 6, 0},
  { "334", 6, 0},
  { "335", 6, 0},
  { "336", 6, 0},
  { "340", 6, 0},
  { "341", 6, 0},
  { "342", 6, 0},
  { "343", 6, 0},
  { "344", 6, 0},
  { "345", 6, 0},
  { "346", 6, 0},
  { "347", 6, 0},
  { "348", 6, 0},
  { "349", 6, 0},
  { "350", 6, 0},
  { "351", 6, 0},
  { "352", 6, 0},
  { "353", 6, 0},
  { "354", 6, 0},
  { "355", 6, 0},
  { "356", 6, 0},
  { "357", 6, 0},
  { "360", 6, 0},
  { "361", 6, 0},
  { "362", 6, 0},
  { "363", 6, 0},
  { "364", 6, 0},
  { "365", 6, 0},
  { "366", 6, 0},
  { "367", 6, 0},
  { "368", 6, 0},
  { "369", 6, 0},
  { "390", VARIABLE_LENGTH, 15},
  { "391", VARIABLE_LENGTH, 18},
  { "392", VARIABLE_LENGTH, 15},
  { "393", VARIABLE_LENGTH, 18},
  { "703", VARIABLE_LENGTH, 30},
};

static const DigitData FOUR_DIGIT_DATA_LENGTH[] {
  // Same format as above

  { "7001", 13, 0},
  { "7002", VARIABLE_LENGTH, 30},
  { "7003", 10, 0},

  { "8001", 14, 0},
  { "8002", VARIABLE_LENGTH, 20},
  { "8003", VARIABLE_LENGTH, 30},
  { "8004", VARIABLE_LENGTH, 30},
  { "8005", 6, 0},
  { "8006", 18, 0},
  { "8007", VARIABLE_LENGTH, 30},
  { "8008", VARIABLE_LENGTH, 12},
  { "8018", 18, 0},
  { "8020", VARIABLE_LENGTH, 25},
  { "8100", 6, 0},
  { "8101", 10, 0},
  { "8102", 2, 0},
  { "8110", VARIABLE_LENGTH, 70},
  { "8200", VARIABLE_LENGTH, 70},
};

String FieldParser::parseFieldsInGeneralPurpose(String rawInformation)
{
    if (rawInformation.getText().empty()) {
        return String("");
    }

    // Processing 2-digit AIs

    if (rawInformation.length() < 2) {
        throw NotFoundException();
    }

    String firstTwoDigits(rawInformation.substring(0, 2)->getText());

    for (DigitData dataLength : TWO_DIGIT_DATA_LENGTH) {
        if (dataLength.digit == firstTwoDigits.getText()) {
            if (dataLength.variableLength == VARIABLE_LENGTH) {
                return processVariableAI(2, dataLength.length, rawInformation);
            }
            return processFixedAI(2, dataLength.variableLength, rawInformation);
        }
    }

    if (rawInformation.length() < 3) {
        throw NotFoundException();
    }

    String firstThreeDigits(rawInformation.substring(0, 3)->getText());

    for (DigitData dataLength : THREE_DIGIT_DATA_LENGTH) {
        if (dataLength.digit == firstThreeDigits.getText()) {
            if (dataLength.variableLength == VARIABLE_LENGTH) {
                return processVariableAI(3, dataLength.length, rawInformation);
            }
            return processFixedAI(3, dataLength.variableLength, rawInformation);
        }
    }


    for (DigitData dataLength : THREE_DIGIT_PLUS_DIGIT_DATA_LENGTH) {
        if (dataLength.digit == firstThreeDigits.getText()) {
            if (dataLength.variableLength == VARIABLE_LENGTH) {
                return processVariableAI(4, dataLength.length, rawInformation);
            }
            return processFixedAI(4, dataLength.variableLength, rawInformation);
        }
    }

    if (rawInformation.length() < 4) {
        throw NotFoundException();
    }

    String firstFourDigits(rawInformation.substring(0, 4)->getText());

    for (DigitData dataLength : FOUR_DIGIT_DATA_LENGTH) {
        if (dataLength.digit == firstFourDigits.getText()) {
            if (dataLength.variableLength == VARIABLE_LENGTH) {
                return processVariableAI(4, dataLength.length, rawInformation);
            }
            return processFixedAI(4, dataLength.variableLength, rawInformation);
        }
    }

    throw NotFoundException();
}

String FieldParser::processFixedAI(int aiSize, int fieldSize, String rawInformation)
{
    if (rawInformation.length() < aiSize) {
        throw NotFoundException();
    }

    String ai(rawInformation.substring(0, aiSize)->getText());

    if (rawInformation.length() < aiSize + fieldSize) {
        throw NotFoundException();
    }

    String field(rawInformation.substring(aiSize, /*aiSize +*/ fieldSize)->getText());
    String remaining(rawInformation.substring(aiSize + fieldSize)->getText());
    String result('(' + ai.getText() + ')' + field.getText());
    String parsedAI = parseFieldsInGeneralPurpose(remaining);
    if (parsedAI.getText() == "") {
        return result;
    } else {
        result.append(parsedAI.getText());
        return result;
    }
}

String FieldParser::processVariableAI(int aiSize, int variableFieldSize, String rawInformation)
{
    String ai(rawInformation.substring(0, aiSize)->getText());
    int maxSize = std::min(rawInformation.length(), aiSize + variableFieldSize);
    String field(rawInformation.substring(aiSize, maxSize - aiSize)->getText());
    String remaining(rawInformation.substring(maxSize)->getText());
    String result('(' + ai.getText() + ')' + field.getText());
    String parsedAI = parseFieldsInGeneralPurpose(remaining);
    if (parsedAI.getText() == "") {
        return result;
    } else {
        result.append(parsedAI.getText());
        return result;
    }
}

}
}
}
