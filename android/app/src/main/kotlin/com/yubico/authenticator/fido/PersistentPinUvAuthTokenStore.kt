/*
 * Copyright (C) 2025 Yubico.
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

package com.yubico.authenticator.fido

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.io.File
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.CipherInputStream
import javax.crypto.CipherOutputStream
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class PersistentPinUvAuthTokenStore(private val context: Context) {

    companion object {
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
        private const val KEY_ALIAS = "ppuat_key_alias"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val FILE_NAME = "ppuat.enc"
        private const val PAIR_SEPARATOR = "|"
        private const val ENTRY_SEPARATOR = ";"
    }

    // Add or update a token for an identifier
    fun addToken(identifier: ByteArray, token: ByteArray) {
        val tokens = loadTokens(context).toMutableMap()
        tokens[identifier.toHexString()] = token.toHexString()
        saveTokens(context, tokens)
    }

    // Remove a token by identifier
    fun removeToken(identifier: ByteArray) {
        val tokens = loadTokens(context).toMutableMap()
        tokens.remove(identifier.toHexString())
        saveTokens(context, tokens)
    }

    // Get a token by identifier
    fun findToken(computeIdentifier: (ByteArray) -> ByteArray?): ByteArray? {
        return loadTokens(context).entries
            .firstNotNullOfOrNull { (identHex, ppuatHex) ->
                val ppuatBytes = ppuatHex.hexToByteArray()
                val computedIdent = computeIdentifier(ppuatBytes)?.toHexString()
                if (identHex == computedIdent) ppuatBytes else null
            }
    }

    private fun getOrCreateSecretKey(): SecretKey {
        val keyStore = KeyStore.getInstance(ANDROID_KEY_STORE)
        keyStore.load(null)
        val entry = keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry
        return entry?.secretKey ?: run {
            val keyGenerator =
                KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEY_STORE)
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
        }
    }

    // Serialize the map as "identifier1|ppuat1;identifier2|ppuat2;..."
    private fun saveTokens(context: Context, tokens: Map<String, String>) {
        val secretKey = getOrCreateSecretKey()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        val iv = cipher.iv

        val file = File(context.filesDir, FILE_NAME)
        file.outputStream().use { fos ->
            fos.write(iv.size)
            fos.write(iv)
            CipherOutputStream(fos, cipher).use { cos ->
                val data =
                    tokens.entries.joinToString(ENTRY_SEPARATOR) { "${it.key}$PAIR_SEPARATOR${it.value}" }
                cos.write(data.toByteArray())
            }
        }
    }

    private fun loadTokens(context: Context): Map<String, String> {
        val file = File(context.filesDir, FILE_NAME)
        if (!file.exists()) return emptyMap()
        file.inputStream().use { fis ->
            val ivSize = fis.read()
            val iv = ByteArray(ivSize)
            fis.read(iv)
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val secretKey = getOrCreateSecretKey()
            cipher.init(Cipher.DECRYPT_MODE, secretKey, GCMParameterSpec(128, iv))
            CipherInputStream(fis, cipher).use { cis ->
                val data = cis.readBytes().toString(Charsets.UTF_8)
                if (data.isBlank()) return emptyMap()
                return data.split(ENTRY_SEPARATOR)
                    .mapNotNull {
                        val parts = it.split(PAIR_SEPARATOR, limit = 2)
                        if (parts.size == 2) parts[0] to parts[1] else null
                    }
                    .toMap()
            }
        }
    }
}