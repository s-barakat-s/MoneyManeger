import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/transfer.dart';
import '../application/transfer_providers.dart';

final transfersStreamProvider = StreamProvider.autoDispose<List<Transfer>>((
  ref,
) {
  return ref.watch(watchTransfersProvider)();
});
