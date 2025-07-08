import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_ai/firebase_ai.dart'; // Removed - using REST API instead
import 'package:revision/core/services/circuit_breaker.dart';
import 'package:revision/core/services/error_handler_service.dart';
import 'package:revision/core/services/firebase_ai_remote_config_service.dart';
import 'package:revision/core/services/gemini_ai_service.dart';
import 'package:revision/core/services/gemini_pipeline_service.dart';
import 'package:revision/core/services/image_save_service.dart';
import 'package:revision/core/services/logging_service.dart';
// Enhanced service locator components
import 'package:revision/core/di/enhanced_service_locator.dart';
import 'package:revision/core/di/service_locator_validator.dart';
import 'package:revision/core/di/service_health_monitor.dart';
import 'package:revision/core/di/service_recovery_manager.dart';
import 'package:revision/core/utils/enhanced_logger.dart';
import 'package:revision/core/services/error_monitoring/production_error_monitor_v2.dart';
import 'package:revision/core/services/error_monitoring/error_monitoring_config.dart';
import 'package:revision/core/utils/null_safety_utils.dart';
// AI processing feature
import 'package:revision/features/ai_processing/data/services/ai_result_save_service.dart';
import 'package:revision/features/ai_processing/domain/usecases/generate_segmentation_masks_usecase.dart';
import 'package:revision/features/ai_processing/domain/usecases/process_image_with_gemini_usecase.dart';
import 'package:revision/features/ai_processing/presentation/cubit/gemini_pipeline_cubit.dart';
import 'package:revision/features/authentication/data/datasources/firebase_auth_data_source.dart';
import 'package:revision/features/authentication/data/repositories/firebase_authentication_repository.dart';
import 'package:revision/features/authentication/domain/repositories/auth_repository.dart';
import 'package:revision/features/authentication/domain/usecases/get_auth_state_changes_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/get_current_user_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_out_usecase.dart';
import 'package:revision/features/authentication/domain/usecases/sign_up_usecase.dart';
import 'package:revision/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/login_bloc.dart';
import 'package:revision/features/authentication/presentation/blocs/signup_bloc.dart';
import 'package:revision/features/image_editing/presentation/cubit/image_editor_cubit.dart';
import 'package:revision/features/image_selection/data/datasources/image_picker_data_source.dart';
import 'package:revision/features/image_selection/data/repositories/image_selection_repository_impl.dart';
import 'package:revision/features/image_selection/domain/repositories/image_selection_repository.dart'
    as image_selection;
import 'package:revision/features/image_selection/domain/usecases/select_image_use_case.dart';
import 'package:revision/features/image_selection/presentation/cubit/image_selection_cubit.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Enhanced logger for service locator
final _logger = EnhancedLogger();

/// Set up all dependencies in the service locator with enhanced validation and monitoring
Future<void> setupServiceLocator({
  bool enableValidation = true,
  bool enableHealthMonitoring = true,
}) async {
  _logger.info('Starting service locator setup', operation: 'SERVICE_LOCATOR_SETUP');

  try {
    // Initialize error monitoring first
    if (!ProductionErrorMonitorV2._instance != null) {
      ProductionErrorMonitorV2.initialize(
        config: const DefaultErrorMonitoringConfig(),
        logger: _logger,
      );
    }

    // Reset service locator for hot reload safety
    if (getIt.isRegistered<AuthRepository>()) {
      _logger.info(
        'Dependencies already registered, resetting...',
        operation: 'SERVICE_LOCATOR_SETUP',
      );
      getIt.reset();
    }

    // Register core services first
    _registerCoreServices();
    _registerDataSources();
    _registerRepositories();
    _registerUseCases();
    _registerServices();
    _registerBlocs();

    _logger.info('Basic dependencies registered successfully', operation: 'SERVICE_LOCATOR_SETUP');

    // Initialize enhanced service locator if validation is enabled
    if (enableValidation) {
      await EnhancedServiceLocator.initialize(
        getIt: getIt,
        logger: _logger,
      );

      final initResult = await EnhancedServiceLocator.instance.initializeWithValidation();
      
      if (!initResult.isSuccessful) {
        _logger.error(
          'Service locator validation failed',
          operation: 'SERVICE_LOCATOR_SETUP',
          context: initResult.getSummary(),
        );
        
        // Continue with basic setup even if validation fails
        _logger.warning(
          'Continuing with basic service locator setup despite validation failures',
          operation: 'SERVICE_LOCATOR_SETUP',
        );
      } else {
        _logger.info(
          'Service locator setup completed with validation',
          operation: 'SERVICE_LOCATOR_SETUP',
          context: initResult.getSummary(),
        );
      }

      // Register recovery strategies for critical services
      _registerRecoveryStrategies();
    }

    _logger.info('Service locator setup completed successfully', operation: 'SERVICE_LOCATOR_SETUP');
  } catch (e, stackTrace) {
    _logger.error(
      'Service locator setup failed: $e',
      operation: 'SERVICE_LOCATOR_SETUP',
      error: e,
      stackTrace: stackTrace,
    );
    
    // Record error in monitoring system
    if (ProductionErrorMonitorV2._instance != null) {
      ProductionErrorMonitorV2.instance.recordError(
        error: e,
        stackTrace: stackTrace,
        context: 'setupServiceLocator',
      );
    }
    
    rethrow;
  }
}

/// Shutdown service locator with proper cleanup
void shutdownServiceLocator() {
  _logger.info('Shutting down service locator', operation: 'SERVICE_LOCATOR_SHUTDOWN');
  
  try {
    // Shutdown enhanced service locator if initialized
    if (EnhancedServiceLocator._instance != null) {
      EnhancedServiceLocator.instance.shutdown();
    }
    
    // Reset GetIt
    getIt.reset();
    
    _logger.info('Service locator shutdown completed', operation: 'SERVICE_LOCATOR_SHUTDOWN');
  } catch (e, stackTrace) {
    _logger.error(
      'Error during service locator shutdown: $e',
      operation: 'SERVICE_LOCATOR_SHUTDOWN',
      error: e,
      stackTrace: stackTrace,
    );
  }
}

void _registerCoreServices() {
  _logger.info('Registering core services', operation: 'CORE_SERVICES_REGISTRATION');

  try {
    getIt
      // Core Services with validation
      ..registerLazySingleton<CircuitBreaker>(() {
        final circuitBreaker = CircuitBreaker();
        return NullSafetyUtils.requireNonNull(
          circuitBreaker,
          message: 'Failed to create CircuitBreaker',
          context: 'ServiceLocator._registerCoreServices',
        );
      })
      ..registerLazySingleton(() {
        final loggingService = LoggingService.instance;
        return NullSafetyUtils.requireNonNull(
          loggingService,
          message: 'Failed to get LoggingService instance',
          context: 'ServiceLocator._registerCoreServices',
        );
      })
      ..registerLazySingleton(() {
        final errorHandlerService = ErrorHandlerService.instance;
        return NullSafetyUtils.requireNonNull(
          errorHandlerService,
          message: 'Failed to get ErrorHandlerService instance',
          context: 'ServiceLocator._registerCoreServices',
        );
      });

    _logger.info('Registering FirebaseAIRemoteConfigService', operation: 'CORE_SERVICES_REGISTRATION');
    getIt.registerLazySingleton<FirebaseAIRemoteConfigService>(() {
      try {
        final service = FirebaseAIRemoteConfigService();
        return NullSafetyUtils.requireNonNull(
          service,
          message: 'Failed to create FirebaseAIRemoteConfigService',
          context: 'ServiceLocator._registerCoreServices',
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Failed to create FirebaseAIRemoteConfigService: $e',
          operation: 'CORE_SERVICES_REGISTRATION',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });

    _logger.info('Registering GeminiAIService', operation: 'CORE_SERVICES_REGISTRATION');
    getIt.registerLazySingleton<GeminiAIService>(() {
      try {
        final remoteConfigService = getIt<FirebaseAIRemoteConfigService>();
        NullSafetyUtils.requireNonNull(
          remoteConfigService,
          message: 'FirebaseAIRemoteConfigService dependency is null',
          context: 'ServiceLocator._registerCoreServices.GeminiAIService',
        );
        
        final service = GeminiAIService(remoteConfigService: remoteConfigService);
        return NullSafetyUtils.requireNonNull(
          service,
          message: 'Failed to create GeminiAIService',
          context: 'ServiceLocator._registerCoreServices',
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Failed to create GeminiAIService: $e',
          operation: 'CORE_SERVICES_REGISTRATION',
          error: e,
          stackTrace: stackTrace,
        );
        
        // Record error in monitoring system
        if (ProductionErrorMonitorV2._instance != null) {
          ProductionErrorMonitorV2.instance.recordError(
            error: e,
            stackTrace: stackTrace,
            context: 'ServiceLocator._registerCoreServices.GeminiAIService',
          );
        }
        
        rethrow;
      }
    });

    _logger.info('Core services registration completed', operation: 'CORE_SERVICES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Core services registration failed: $e',
      operation: 'CORE_SERVICES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _registerDataSources() {
  _logger.info('Registering data sources', operation: 'DATA_SOURCES_REGISTRATION');

  try {
    // Skip Firebase data sources if already registered (test mode)
    if (!getIt.isRegistered<FirebaseAuthDataSource>()) {
      getIt.registerLazySingleton<FirebaseAuthDataSource>(() {
        try {
          final dataSource = FirebaseAuthDataSourceImpl();
          return NullSafetyUtils.requireNonNull(
            dataSource,
            message: 'Failed to create FirebaseAuthDataSource',
            context: 'ServiceLocator._registerDataSources',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create FirebaseAuthDataSource: $e',
            operation: 'DATA_SOURCES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          
          // Record error in monitoring system
          if (ProductionErrorMonitorV2._instance != null) {
            ProductionErrorMonitorV2.instance.recordError(
              error: e,
              stackTrace: stackTrace,
              context: 'ServiceLocator._registerDataSources.FirebaseAuthDataSource',
            );
          }
          
          rethrow;
        }
      });
    }

    getIt
      ..registerLazySingleton<ImagePicker>(() {
        final imagePicker = ImagePicker();
        return NullSafetyUtils.requireNonNull(
          imagePicker,
          message: 'Failed to create ImagePicker',
          context: 'ServiceLocator._registerDataSources',
        );
      })
      ..registerLazySingleton<ImagePickerDataSource>(() {
        try {
          final imagePicker = getIt<ImagePicker>();
          NullSafetyUtils.requireNonNull(
            imagePicker,
            message: 'ImagePicker dependency is null',
            context: 'ServiceLocator._registerDataSources.ImagePickerDataSource',
          );
          
          final dataSource = ImagePickerDataSource(imagePicker);
          return NullSafetyUtils.requireNonNull(
            dataSource,
            message: 'Failed to create ImagePickerDataSource',
            context: 'ServiceLocator._registerDataSources',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create ImagePickerDataSource: $e',
            operation: 'DATA_SOURCES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      });

    _logger.info('Data sources registration completed', operation: 'DATA_SOURCES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Data sources registration failed: $e',
      operation: 'DATA_SOURCES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _registerRepositories() {
  _logger.info('Registering repositories', operation: 'REPOSITORIES_REGISTRATION');

  try {
    // Skip Firebase repositories if already registered (test mode)
    if (!getIt.isRegistered<AuthRepository>()) {
      getIt.registerLazySingleton<AuthRepository>(() {
        try {
          final firebaseAuthDataSource = getIt<FirebaseAuthDataSource>();
          NullSafetyUtils.requireNonNull(
            firebaseAuthDataSource,
            message: 'FirebaseAuthDataSource dependency is null',
            context: 'ServiceLocator._registerRepositories.AuthRepository',
          );
          
          final repository = FirebaseAuthenticationRepository(
            firebaseAuthDataSource: firebaseAuthDataSource,
          );
          return NullSafetyUtils.requireNonNull(
            repository,
            message: 'Failed to create AuthRepository',
            context: 'ServiceLocator._registerRepositories',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create AuthRepository: $e',
            operation: 'REPOSITORIES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          
          // Record error in monitoring system
          if (ProductionErrorMonitorV2._instance != null) {
            ProductionErrorMonitorV2.instance.recordError(
              error: e,
              stackTrace: stackTrace,
              context: 'ServiceLocator._registerRepositories.AuthRepository',
            );
          }
          
          rethrow;
        }
      });
    }

    getIt.registerLazySingleton<image_selection.ImageRepository>(() {
      try {
        final imagePickerDataSource = getIt<ImagePickerDataSource>();
        NullSafetyUtils.requireNonNull(
          imagePickerDataSource,
          message: 'ImagePickerDataSource dependency is null',
          context: 'ServiceLocator._registerRepositories.ImageRepository',
        );
        
        final repository = ImageSelectionRepositoryImpl(imagePickerDataSource);
        return NullSafetyUtils.requireNonNull(
          repository,
          message: 'Failed to create ImageRepository',
          context: 'ServiceLocator._registerRepositories',
        );
      } catch (e, stackTrace) {
        _logger.error(
          'Failed to create ImageRepository: $e',
          operation: 'REPOSITORIES_REGISTRATION',
          error: e,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });

    _logger.info('Repositories registration completed', operation: 'REPOSITORIES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Repositories registration failed: $e',
      operation: 'REPOSITORIES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _registerUseCases() {
  _logger.info('Registering use cases', operation: 'USE_CASES_REGISTRATION');

  try {
    getIt
      // Use Cases with validation
      ..registerLazySingleton<SignInUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          NullSafetyUtils.requireNonNull(
            authRepository,
            message: 'AuthRepository dependency is null',
            context: 'ServiceLocator._registerUseCases.SignInUseCase',
          );
          
          final useCase = SignInUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SignInUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SignInUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<SignInWithGoogleUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = SignInWithGoogleUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SignInWithGoogleUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SignInWithGoogleUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<SignUpUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = SignUpUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SignUpUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SignUpUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<SignOutUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = SignOutUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SignOutUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SignOutUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<SendPasswordResetEmailUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = SendPasswordResetEmailUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SendPasswordResetEmailUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SendPasswordResetEmailUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<GetCurrentUserUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = GetCurrentUserUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create GetCurrentUserUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create GetCurrentUserUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<GetAuthStateChangesUseCase>(() {
        try {
          final authRepository = getIt<AuthRepository>();
          final useCase = GetAuthStateChangesUseCase(authRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create GetAuthStateChangesUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create GetAuthStateChangesUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<SelectImageUseCase>(() {
        try {
          final imageRepository = getIt<image_selection.ImageRepository>();
          final useCase = SelectImageUseCase(imageRepository);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create SelectImageUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SelectImageUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<ProcessImageWithGeminiUseCase>(() {
        try {
          final geminiPipelineService = getIt<GeminiPipelineService>();
          final useCase = ProcessImageWithGeminiUseCase(geminiPipelineService);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create ProcessImageWithGeminiUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create ProcessImageWithGeminiUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<GenerateSegmentationMasksUseCase>(() {
        try {
          final geminiAIService = getIt<GeminiAIService>();
          final useCase = GenerateSegmentationMasksUseCase(geminiAIService);
          return NullSafetyUtils.requireNonNull(
            useCase,
            message: 'Failed to create GenerateSegmentationMasksUseCase',
            context: 'ServiceLocator._registerUseCases',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create GenerateSegmentationMasksUseCase: $e',
            operation: 'USE_CASES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      });

    _logger.info('Use cases registration completed', operation: 'USE_CASES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Use cases registration failed: $e',
      operation: 'USE_CASES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _registerServices() {
  _logger.info('Registering services', operation: 'SERVICES_REGISTRATION');

  try {
    getIt
      ..registerLazySingleton<ImageSaveService>(() {
        try {
          final service = ImageSaveService();
          return NullSafetyUtils.requireNonNull(
            service,
            message: 'Failed to create ImageSaveService',
            context: 'ServiceLocator._registerServices',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create ImageSaveService: $e',
            operation: 'SERVICES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<AIResultSaveService>(() {
        try {
          final service = AIResultSaveService();
          return NullSafetyUtils.requireNonNull(
            service,
            message: 'Failed to create AIResultSaveService',
            context: 'ServiceLocator._registerServices',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create AIResultSaveService: $e',
            operation: 'SERVICES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerLazySingleton<GeminiPipelineService>(() {
        try {
          final geminiAIService = getIt<GeminiAIService>();
          NullSafetyUtils.requireNonNull(
            geminiAIService,
            message: 'GeminiAIService dependency is null',
            context: 'ServiceLocator._registerServices.GeminiPipelineService',
          );
          
          final service = GeminiPipelineService(geminiAIService: geminiAIService);
          return NullSafetyUtils.requireNonNull(
            service,
            message: 'Failed to create GeminiPipelineService',
            context: 'ServiceLocator._registerServices',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create GeminiPipelineService: $e',
            operation: 'SERVICES_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      });

    _logger.info('Services registration completed', operation: 'SERVICES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Services registration failed: $e',
      operation: 'SERVICES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

void _registerUseCases() {
  getIt
    // Use Cases
    ..registerLazySingleton<SignInUseCase>(() {
      try {
        return SignInUseCase(getIt<AuthRepository>());
      } catch (e) {
        debugPrint('Error while creating SignInUseCase: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        rethrow;
      }
    })
    ..registerLazySingleton<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<SignUpUseCase>(
      () => SignUpUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<SignOutUseCase>(() {
      try {
        return SignOutUseCase(getIt<AuthRepository>());
      } catch (e) {
        debugPrint('Error while creating SignOutUseCase: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        rethrow;
      }
    })
    ..registerLazySingleton<SendPasswordResetEmailUseCase>(
      () => SendPasswordResetEmailUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(getIt<AuthRepository>()),
    )
    ..registerLazySingleton<GetAuthStateChangesUseCase>(() {
      try {
        return GetAuthStateChangesUseCase(getIt<AuthRepository>());
      } catch (e) {
        debugPrint('Error while creating GetAuthStateChangesUseCase: $e');
        debugPrint('Stack trace: ${StackTrace.current}');
        rethrow;
      }
    })
    ..registerLazySingleton<SelectImageUseCase>(
      () => SelectImageUseCase(getIt<image_selection.ImageRepository>()),
    )
    ..registerLazySingleton<ProcessImageWithGeminiUseCase>(
      () => ProcessImageWithGeminiUseCase(getIt<GeminiPipelineService>()),
    )
    ..registerLazySingleton<GenerateSegmentationMasksUseCase>(
      () => GenerateSegmentationMasksUseCase(getIt<GeminiAIService>()),
    );
}

void _registerServices() {
  getIt
    ..registerLazySingleton<ImageSaveService>(ImageSaveService.new)
    ..registerLazySingleton<AIResultSaveService>(AIResultSaveService.new)
    ..registerLazySingleton<GeminiPipelineService>(
      () => GeminiPipelineService(geminiAIService: getIt<GeminiAIService>()),
    );
}

void _registerBlocs() {
  _logger.info('Registering blocs and cubits', operation: 'BLOCS_REGISTRATION');

  try {
    getIt
      // BLoCs and Cubits with validation
      ..registerFactory<AuthenticationBloc>(() {
        try {
          final getAuthStateChanges = getIt<GetAuthStateChangesUseCase>();
          final signOut = getIt<SignOutUseCase>();
          
          NullSafetyUtils.requireNonNull(
            getAuthStateChanges,
            message: 'GetAuthStateChangesUseCase dependency is null',
            context: 'ServiceLocator._registerBlocs.AuthenticationBloc',
          );
          NullSafetyUtils.requireNonNull(
            signOut,
            message: 'SignOutUseCase dependency is null',
            context: 'ServiceLocator._registerBlocs.AuthenticationBloc',
          );
          
          final bloc = AuthenticationBloc(
            getAuthStateChanges: getAuthStateChanges,
            signOut: signOut,
          );
          return NullSafetyUtils.requireNonNull(
            bloc,
            message: 'Failed to create AuthenticationBloc',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create AuthenticationBloc: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerFactory<LoginBloc>(() {
        try {
          final signIn = getIt<SignInUseCase>();
          final signInWithGoogle = getIt<SignInWithGoogleUseCase>();
          final sendPasswordResetEmail = getIt<SendPasswordResetEmailUseCase>();
          
          final bloc = LoginBloc(
            signIn: signIn,
            signInWithGoogle: signInWithGoogle,
            sendPasswordResetEmail: sendPasswordResetEmail,
          );
          return NullSafetyUtils.requireNonNull(
            bloc,
            message: 'Failed to create LoginBloc',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create LoginBloc: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerFactory<SignupBloc>(() {
        try {
          final signUp = getIt<SignUpUseCase>();
          final bloc = SignupBloc(signUp: signUp);
          return NullSafetyUtils.requireNonNull(
            bloc,
            message: 'Failed to create SignupBloc',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create SignupBloc: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerFactory<ImageSelectionCubit>(() {
        try {
          final selectImageUseCase = getIt<SelectImageUseCase>();
          final cubit = ImageSelectionCubit(selectImageUseCase);
          return NullSafetyUtils.requireNonNull(
            cubit,
            message: 'Failed to create ImageSelectionCubit',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create ImageSelectionCubit: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerFactory<ImageEditorCubit>(() {
        try {
          final cubit = ImageEditorCubit();
          return NullSafetyUtils.requireNonNull(
            cubit,
            message: 'Failed to create ImageEditorCubit',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create ImageEditorCubit: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      })
      ..registerFactory<GeminiPipelineCubit>(() {
        try {
          final processImageWithGemini = getIt<ProcessImageWithGeminiUseCase>();
          final cubit = GeminiPipelineCubit(processImageWithGemini);
          return NullSafetyUtils.requireNonNull(
            cubit,
            message: 'Failed to create GeminiPipelineCubit',
            context: 'ServiceLocator._registerBlocs',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'Failed to create GeminiPipelineCubit: $e',
            operation: 'BLOCS_REGISTRATION',
            error: e,
            stackTrace: stackTrace,
          );
          rethrow;
        }
      });

    _logger.info('Blocs and cubits registration completed', operation: 'BLOCS_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Blocs and cubits registration failed: $e',
      operation: 'BLOCS_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Register recovery strategies for critical services
void _registerRecoveryStrategies() {
  _logger.info('Registering recovery strategies', operation: 'RECOVERY_STRATEGIES_REGISTRATION');

  try {
    // Register recovery strategy for AuthRepository
    EnhancedServiceLocator.instance.registerRecoveryStrategy<AuthRepository>(
      ReregisterRecoveryStrategy((getIt) async {
        _logger.info('Attempting to re-register AuthRepository', operation: 'RECOVERY_STRATEGY');
        
        // Remove existing registration
        if (getIt.isRegistered<AuthRepository>()) {
          getIt.unregister<AuthRepository>();
        }
        
        // Re-register with fresh instance
        getIt.registerLazySingleton<AuthRepository>(() {
          final firebaseAuthDataSource = getIt<FirebaseAuthDataSource>();
          return FirebaseAuthenticationRepository(
            firebaseAuthDataSource: firebaseAuthDataSource,
          );
        });
      }),
    );

    // Register recovery strategy for GeminiAIService
    EnhancedServiceLocator.instance.registerRecoveryStrategy<GeminiAIService>(
      ReregisterRecoveryStrategy((getIt) async {
        _logger.info('Attempting to re-register GeminiAIService', operation: 'RECOVERY_STRATEGY');
        
        // Remove existing registration
        if (getIt.isRegistered<GeminiAIService>()) {
          getIt.unregister<GeminiAIService>();
        }
        
        // Re-register with fresh instance
        getIt.registerLazySingleton<GeminiAIService>(() {
          final remoteConfigService = getIt<FirebaseAIRemoteConfigService>();
          return GeminiAIService(remoteConfigService: remoteConfigService);
        });
      }),
    );

    // Register recovery strategy for FirebaseAIRemoteConfigService
    EnhancedServiceLocator.instance.registerRecoveryStrategy<FirebaseAIRemoteConfigService>(
      ReregisterRecoveryStrategy((getIt) async {
        _logger.info('Attempting to re-register FirebaseAIRemoteConfigService', operation: 'RECOVERY_STRATEGY');
        
        // Remove existing registration
        if (getIt.isRegistered<FirebaseAIRemoteConfigService>()) {
          getIt.unregister<FirebaseAIRemoteConfigService>();
        }
        
        // Re-register with fresh instance
        getIt.registerLazySingleton<FirebaseAIRemoteConfigService>(() {
          return FirebaseAIRemoteConfigService();
        });
      }),
    );

    _logger.info('Recovery strategies registration completed', operation: 'RECOVERY_STRATEGIES_REGISTRATION');
  } catch (e, stackTrace) {
    _logger.error(
      'Recovery strategies registration failed: $e',
      operation: 'RECOVERY_STRATEGIES_REGISTRATION',
      error: e,
      stackTrace: stackTrace,
    );
    // Don't rethrow - recovery strategies are optional
  }
}
