import 'package:flutter/cupertino.dart';
import 'app_utils.dart';

// Notice - all these uploads needs to be done in sync with robot - the process is as follows:
// Send numOfMoves, flag = 4
// Recieve flag = 0
// Send pulse, flag = 1
// Recieve flag = 0
// Send next pulse, flag = 1
// Recieve flag = 0
// Finished pulses, set flag = 2
// Robot start painting, after done, flag = 0.
// If error occurs, flag = 3 and app reupload cur pulse.

Future<void> startUploading(List<CompMove> compressedMoves) async {
  final int numOfMoves = compressedMoves.length;
  if (numOfMoves > maxNumOfCompMoves) {
    debugPrint("Painting too large!!!");
    return;
  }
  // Rounding num of pulses - for example, for 1200 points, we need 3 pulses. The last one will contain 200.
  int numOfPulses = numOfMoves ~/ pulseCapacity;
  if (numOfMoves % pulseCapacity != 0) {
    numOfPulses++;
  }
  await uploadNumOfMoves(numOfMoves);

  for (int curPulse = 0; curPulse <= numOfPulses; curPulse++) {
    var pulseStatus = await prepareForNextPulse(curPulse, numOfPulses);
    if (pulseStatus == PulseStatus.finishedPulses) {
      return;
    }
    // When robot got an error, reupload current pulse.
    if (pulseStatus == PulseStatus.reuploadPulse) {
      curPulse--;
    }
    await movesRef.remove();
    int curNumOfMoves = pulseCapacity;
    if (curPulse == numOfPulses - 1 && (numOfMoves % pulseCapacity != 0)) {
      curNumOfMoves = numOfMoves % pulseCapacity;
    }
    await uploadCurPulse(compressedMoves, curNumOfMoves, curPulse);
    await flagRef.set(UploadFlag.readingPulse.index);
  }
}

// First thing, so robot will know how big the array it needs for allocation.
Future<void> uploadNumOfMoves(int numOfMoves) async {
  numOfMovesRef.set(numOfMoves * 2);
  movesRef.remove();
  await flagRef.set(UploadFlag.sendNumOfMoves.index);
  var flagVal = await flagRef.get();
  while (flagVal.value != UploadFlag.readyForPulse.index) {
    flagVal = await flagRef.get();
  }
}

Future<void> uploadCurPulse(List<CompMove> compressedMoves, int curNumOfMoves, int curPulse) async {
  await movesRef.child("0").set(curNumOfMoves * 2);
  for (int i = 1; i < curNumOfMoves + 1; i++) {
    final int curMoveIndex = i - 1 + pulseCapacity * curPulse;
    movesRef.child((2 * i - 1).toString()).set(compressedMoves[curMoveIndex].num);
    movesRef.child((2 * i).toString()).set(compressedMoves[curMoveIndex].move.index);
  }
}

Future<PulseStatus> prepareForNextPulse(int curPulse, int numOfPulses) async {
  var flagVal = await flagRef.get();
  while (flagVal.value == UploadFlag.readingPulse.index) {
    flagVal = await flagRef.get();
  }
  if (flagVal.value == UploadFlag.reuploadLast.index) {
    if (curPulse > 0) {
      return PulseStatus.reuploadPulse;
    }
  }
  if (curPulse == numOfPulses) {
    await flagRef.set(UploadFlag.startDraw.index);
    return PulseStatus.finishedPulses;
  }
  return PulseStatus.nextPulse;
}
