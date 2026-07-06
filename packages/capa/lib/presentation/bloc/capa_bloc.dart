import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capa/domain/usecases/get_capas.dart';
import 'package:capa/domain/usecases/get_capa_detail.dart';
import 'package:capa/domain/usecases/create_capa.dart';
import 'package:capa/domain/usecases/closeout_capa.dart';
import 'package:capa/domain/repositories/capa_repository.dart';
import 'capa_event.dart';
import 'capa_state.dart';

class CapaBloc extends Bloc<CapaEvent, CapaState> {
  final GetCapas getCapas;
  final GetCapaDetail getCapaDetail;
  final CreateCapa createCapa;
  final CloseoutCapa closeoutCapa;
  final CapaRepository repository; // ✅ untuk updateCapaStatus

  CapaBloc({
    required this.getCapas,
    required this.getCapaDetail,
    required this.createCapa,
    required this.closeoutCapa,
    required this.repository,
  }) : super(CapaInitial()) {
    on<LoadCapas>(_onLoadCapas);
    on<LoadCapaDetail>(_onLoadCapaDetail);
    on<CreateCapaEvent>(_onCreateCapa);
    on<UpdateCapaStatusEvent>(_onUpdateCapaStatus); // ✅
    on<CloseoutCapaEvent>(_onCloseoutCapa);
  }

  Future<void> _onLoadCapas(LoadCapas event, Emitter<CapaState> emit) async {
    emit(CapaLoading());
    try {
      final capas = await getCapas();
      emit(CapaLoaded(capas: capas));
    } catch (e) {
      emit(CapaError(message: e.toString()));
    }
  }

  Future<void> _onLoadCapaDetail(LoadCapaDetail event, Emitter<CapaState> emit) async {
    emit(CapaLoading());
    try {
      final capa = await getCapaDetail(event.id);
      emit(CapaDetailLoaded(capa: capa));
    } catch (e) {
      emit(CapaError(message: e.toString()));
    }
  }

  Future<void> _onCreateCapa(CreateCapaEvent event, Emitter<CapaState> emit) async {
    emit(CapaLoading());
    try {
      final capa = await createCapa(
        findingId: event.findingId,
        rootCause: event.rootCause,
        correctiveAction: event.correctiveAction,
        preventiveAction: event.preventiveAction,
        picId: event.picId,
        deadline: event.deadline,
      );
      emit(CapaCreated(capa: capa));
      final capas = await getCapas();
      emit(CapaLoaded(capas: capas));
    } catch (e) {
      emit(CapaError(message: e.toString()));
    }
  }

  // ✅ handler baru untuk update status dari card
  Future<void> _onUpdateCapaStatus(UpdateCapaStatusEvent event, Emitter<CapaState> emit) async {
    try {
      if (event.status == 'Closed') {
        final prefs = await SharedPreferences.getInstance();
        String userId = prefs.getString('user_id') ?? '';
        
        // ASP.NET Core JSON parser strict require valid Guid format (36 chars with hyphens)
        // If not valid, it throws: "The JSON value could not be converted to System.Nullable`1[System.Guid]"
        if (userId.length != 36) {
          userId = '00000000-0000-0000-0000-000000000001'; // Fallback valid guid to avoid crash
        }

        await closeoutCapa(
          id: event.id,
          isEffective: true,
          verificationNotes: 'Auto-closed from list status update',
          verifiedById: userId,
        );
      } else {
        await repository.updateCapaStatus(id: event.id, status: event.status);
      }
      
      final capas = await getCapas();
      emit(CapaLoaded(capas: capas));
    } catch (e) {
      emit(CapaError(message: e.toString()));
    }
  }

  Future<void> _onCloseoutCapa(CloseoutCapaEvent event, Emitter<CapaState> emit) async {
    emit(CapaLoading());
    try {
      await closeoutCapa(
        id: event.id,
        isEffective: event.isEffective,
        verificationNotes: event.verificationNotes,
        verifiedById: event.verifiedById,
      );
      emit(CapaClosed());
      final capas = await getCapas();
      emit(CapaLoaded(capas: capas));
    } catch (e) {
      emit(CapaError(message: e.toString()));
    }
  }
}