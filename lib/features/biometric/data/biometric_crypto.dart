import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A device key pair for fingerprint sign-in.
///
/// The PUBLIC key (PEM) is sent to the backend when the user turns fingerprint login on.
/// The PRIVATE key never leaves the phone: it is kept in secure storage and only used to
/// sign a one-time challenge after the fingerprint was confirmed.
class BiometricKeyPair {
  const BiometricKeyPair({
    required this.privateKeyHex,
    required this.publicKeyPem,
  });

  final String privateKeyHex;
  final String publicKeyPem;
}

/// ECDSA P-256 / SHA-256, exactly what the backend verifies
/// (`ECDSA_P256_SHA256`, signature = DER, base64 encoded).
/// No statics: the crypto helpers live on an instance.
class BiometricCrypto {
  BiometricCrypto();

  final ECDomainParameters _curve = ECCurve_secp256r1();

  /// DER header of a SubjectPublicKeyInfo that holds an uncompressed P-256 point.
  /// The 65 bytes `04 || X || Y` follow it.
  final List<int> _spkiPrefix = const [
    0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
    0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
    0x42, 0x00,
  ];

  BiometricKeyPair generate() {
    final generator = ECKeyGenerator()
      ..init(
        ParametersWithRandom(
          ECKeyGeneratorParameters(_curve),
          _secureRandom(),
        ),
      );

    final pair = generator.generateKeyPair();
    final privateKey = pair.privateKey as ECPrivateKey;
    final publicKey = pair.publicKey as ECPublicKey;

    final point = publicKey.Q!.getEncoded(false); // 04 || X || Y
    final der = Uint8List.fromList([..._spkiPrefix, ...point]);

    return BiometricKeyPair(
      privateKeyHex: privateKey.d!.toRadixString(16),
      publicKeyPem: _toPem(der),
    );
  }

  /// Signs [message] (the server nonce, UTF-8) and returns the base64 DER signature.
  String sign(String privateKeyHex, String message) {
    final d = BigInt.parse(privateKeyHex, radix: 16);

    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(true, PrivateKeyParameter<ECPrivateKey>(ECPrivateKey(d, _curve)));

    final signature = signer.generateSignature(
      Uint8List.fromList(utf8.encode(message)),
    ) as ECSignature;

    return base64.encode(_derSignature(signature.r, signature.s));
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  SecureRandom _secureRandom() {
    final random = FortunaRandom();
    final source = Random.secure();

    random.seed(
      KeyParameter(
        Uint8List.fromList(
          List<int>.generate(32, (_) => source.nextInt(256)),
        ),
      ),
    );

    return random;
  }

  Uint8List _derSignature(BigInt r, BigInt s) {
    final body = [..._derInteger(r), ..._derInteger(s)];
    return Uint8List.fromList([0x30, body.length, ...body]);
  }

  List<int> _derInteger(BigInt value) {
    var bytes = _bigIntToBytes(value);

    if (bytes.isEmpty) bytes = [0];
    if (bytes.first & 0x80 != 0) bytes = [0, ...bytes];

    return [0x02, bytes.length, ...bytes];
  }

  List<int> _bigIntToBytes(BigInt value) {
    var hex = value.toRadixString(16);
    if (hex.length.isOdd) hex = '0$hex';

    return [
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
  }

  String _toPem(Uint8List der) {
    final b64 = base64.encode(der);

    final lines = [
      for (var i = 0; i < b64.length; i += 64)
        b64.substring(i, min(i + 64, b64.length)),
    ];

    return '-----BEGIN PUBLIC KEY-----\n${lines.join('\n')}\n-----END PUBLIC KEY-----\n';
  }
}

/// The single instance used across the app (injected, not static).
final BiometricCrypto biometricCrypto = BiometricCrypto();
