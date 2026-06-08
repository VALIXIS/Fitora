import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() {
  final dir = Directory('assets/sounds');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  // Generate a simple 100ms beep at 440Hz
  final int sampleRate = 44100;
  final double durationInSeconds = 0.1;
  final int numSamples = (sampleRate * durationInSeconds).toInt();
  final int numChannels = 1;
  final int bitsPerSample = 16;
  
  final int byteRate = sampleRate * numChannels * (bitsPerSample ~/ 8);
  final int blockAlign = numChannels * (bitsPerSample ~/ 8);
  final int subchunk2Size = numSamples * numChannels * (bitsPerSample ~/ 8);
  final int chunkSize = 36 + subchunk2Size;

  final builder = BytesBuilder();
  
  // RIFF header
  builder.add('RIFF'.codeUnits);
  builder.add(_int32ToBytes(chunkSize));
  builder.add('WAVE'.codeUnits);
  
  // fmt subchunk
  builder.add('fmt '.codeUnits);
  builder.add(_int32ToBytes(16)); // Subchunk1Size
  builder.add(_int16ToBytes(1));  // AudioFormat (PCM)
  builder.add(_int16ToBytes(numChannels));
  builder.add(_int32ToBytes(sampleRate));
  builder.add(_int32ToBytes(byteRate));
  builder.add(_int16ToBytes(blockAlign));
  builder.add(_int16ToBytes(bitsPerSample));
  
  // data subchunk
  builder.add('data'.codeUnits);
  builder.add(_int32ToBytes(subchunk2Size));
  
  // Generate samples
  for (int i = 0; i < numSamples; i++) {
    // 880Hz sine wave, decaying volume
    double t = i / sampleRate;
    double envelope = 1.0 - (i / numSamples);
    double value = sin(2 * pi * 880 * t) * envelope;
    int sample = (value * 32767).toInt();
    builder.add(_int16ToBytes(sample));
  }
  
  final file = File('assets/sounds/bloop.wav');
  file.writeAsBytesSync(builder.toBytes());
  print('Generated assets/sounds/bloop.wav');
}

List<int> _int16ToBytes(int value) {
  return [value & 0xff, (value >> 8) & 0xff];
}

List<int> _int32ToBytes(int value) {
  return [
    value & 0xff,
    (value >> 8) & 0xff,
    (value >> 16) & 0xff,
    (value >> 24) & 0xff,
  ];
}
