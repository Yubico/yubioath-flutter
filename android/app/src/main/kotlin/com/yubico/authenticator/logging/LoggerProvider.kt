/*
 * Copyright (C) 2023 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.yubico.authenticator.logging

import org.slf4j.ILoggerFactory
import org.slf4j.IMarkerFactory
import org.slf4j.helpers.BasicMarkerFactory
import org.slf4j.helpers.NOPMDCAdapter
import org.slf4j.spi.MDCAdapter
import org.slf4j.spi.SLF4JServiceProvider

class LoggerProvider : SLF4JServiceProvider {
    private var loggerFactory: ILoggerFactory? = null
    private var markerFactory: IMarkerFactory? = null
    private var mdcAdapter: MDCAdapter? = null
    override fun getLoggerFactory(): ILoggerFactory {
        return loggerFactory!!
    }

    override fun getMarkerFactory(): IMarkerFactory {
        return markerFactory!!
    }

    override fun getMDCAdapter(): MDCAdapter {
        return mdcAdapter!!
    }

    override fun getRequestedApiVersion(): String {
        return "2.0.99"
    }

    override fun initialize() {
        loggerFactory = LoggerFactory()
        markerFactory = BasicMarkerFactory()
        mdcAdapter = NOPMDCAdapter()
    }
}