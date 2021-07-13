/*
* Copyright 2008 ZXing authors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* 2019-05-08 translation from Java into C++
*/

#include <zxing/ResultMetadata.h>
#include <zxing/common/ByteArray.h>

namespace zxing {

struct ResultMetadata::Value
{
    virtual ~Value() {}
    virtual int toInteger(int fallback) const {
        return fallback;
    }
    virtual std::string toString() const {
        return std::string();
    }
};

struct ResultMetadata::IntegerValue : public Value
{
    int value;
    explicit IntegerValue(int v) : value(v) {}
    int toInteger(int) const override {
        return value;
    }
};

struct ResultMetadata::StringValue : public Value
{
    std::string value;
    explicit StringValue(std::string v) : value(std::move(v)) {}
    std::string toString() const override {
        return value;
    }
};

int ResultMetadata::getInt(Key key, int fallbackValue) const
{
    std::map<Key, std::shared_ptr<Value>>::const_iterator it = _contents.find(key);
    return it != _contents.end() ? it->second->toInteger(fallbackValue) : fallbackValue;
}

std::string ResultMetadata::getString(Key key) const {
    std::map<Key, std::shared_ptr<Value>>::const_iterator it = _contents.find(key);
    return it != _contents.end() ? it->second->toString() : std::string();
}

void ResultMetadata::put(Key key, int value) {
    _contents[key] = std::make_shared<IntegerValue>(value);
}

void ResultMetadata::put(Key key, const std::string &value) {
    _contents[key] = std::make_shared<StringValue>(value);
}

void ResultMetadata::putAll(const ResultMetadata& other) {
    _contents.insert(other._contents.begin(), other._contents.end());
}

std::list<ResultMetadata::Key> ResultMetadata::keys() const
{
    std::list<Key> keys;
    for(std::map<Key, std::shared_ptr<Value>>::const_iterator it = _contents.begin(); it != _contents.end(); ++it) {
        keys.push_back(it->first);
    }

    return keys;
}

bool ResultMetadata::empty() const
{
    return _contents.empty();
}

std::string ResultMetadata::keyToString(Key key) const
{
    switch (key)
    {
    case OTHER:                         return "OTHER";
    case ORIENTATION:                   return "ORIENTATION";
    case BYTE_SEGMENTS:                 return "BYTE_SEGMENTS";
    case ERROR_CORRECTION_LEVEL:        return "ERROR_CORRECTION_LEVEL";
    case ISSUE_NUMBER:                  return "ISSUE_NUMBER";
    case SUGGESTED_PRICE:               return "SUGGESTED_PRICE";
    case POSSIBLE_COUNTRY:              return "POSSIBLE_COUNTRY";
    case UPC_EAN_EXTENSION:             return "UPC_EAN_EXTENSION";
    case PDF417_EXTRA_METADATA:         return "PDF417_EXTRA_METADATA";
    case STRUCTURED_APPEND_SEQUENCE:    return "STRUCTURED_APPEND_SEQUENCE";
    case STRUCTURED_APPEND_CODE_COUNT:  return "STRUCTURED_APPEND_CODE_COUNT";
    case STRUCTURED_APPEND_PARITY:      return "STRUCTURED_APPEND_PARITY";
    }
    return "UNKNOWN";
}

} // zxing
