import groovy.json.JsonBuilder
import io.jsonwebtoken.io.Decoders
import io.jsonwebtoken.io.Encoders
import io.jsonwebtoken.Jwts
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom
import java.time.Instant
import java.time.temporal.ChronoUnit
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec

class EncryptedMessage {
    String c
    String n
    String t
}

def e2eEncrypt(String message, String symmetricKeyBase64) {
  def groupSecret = Decoders.BASE64.decode(symmetricKeyBase64)

  def secretKey = new SecretKeySpec(groupSecret, 'AES')
  def cipher = Cipher.getInstance('AES/GCM/NoPadding')
  cipher.init(Cipher.ENCRYPT_MODE, secretKey)

  def messageBytes = message.getBytes(StandardCharsets.UTF_8)
  def ciphertextAndIntegrityCheck = cipher.doFinal(messageBytes)

  def totalLength = ciphertextAndIntegrityCheck.length
  def ciphertextLength = totalLength - 16
  def ciphertext = Encoders.BASE64.encode(Arrays.copyOfRange(ciphertextAndIntegrityCheck, 0, ciphertextLength))
  def integrityCheck = Encoders.BASE64.encode(Arrays.copyOfRange(ciphertextAndIntegrityCheck, ciphertextLength, totalLength))
  def initializationVector = Encoders.BASE64.encode(cipher.getIV())

  def encryptedMessage = new EncryptedMessage(c: ciphertext, n: initializationVector, t: integrityCheck)
  return new JsonBuilder(encryptedMessage).toString()
}

def jwt(keyPair, String userId) {
  if (!keyPair) { return "Warning: jwt expected keyPair" }

  return Jwts.builder()
    .setExpiration(Date.from(Instant.now().plus(1L, ChronoUnit.MINUTES)))
    .claim("scp", "*")
    .setSubject("${userId}")
    .signWith(keyPair.private)
    .compact()
}
