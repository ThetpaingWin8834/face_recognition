sealed class LivenessCheckError {
  
}

final class InitializedError extends LivenessCheckError{
  final String message;
  final Object? rawError;
@override
String toString() => message;
  InitializedError({required this.message, required this.rawError});
}