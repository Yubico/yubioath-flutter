/*
 * Copyright (C) 2022 Yubico.
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

package com.yubico.authenticator.ndef;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/**
 * Created by dain on 2/17/14.
 */
public abstract class KeyboardLayout {
    private static final Map<String, KeyboardLayout> layouts = new HashMap<String, KeyboardLayout>();

    static {
        layouts.put("US", new USKeyboardLayout());
        layouts.put("DE", new DEKeyboardLayout());
        layouts.put("DE-CH", new DECHKeyboardLayout());
    }

    public static KeyboardLayout forName(String name) {
        return layouts.get(name.toUpperCase());
    }

    public static Set<String> availableLayouts() {
        return new TreeSet<>(layouts.keySet());
    }

    protected static final int SHIFT = 0x80;

    protected abstract String fromScanCode(int code);

    public final String fromScanCodes(byte[] bytes) {
        StringBuilder buf = new StringBuilder();
        for (byte b : bytes) {
            buf.append(fromScanCode(b & 0xff));
        }

        return buf.toString();
    }
}
