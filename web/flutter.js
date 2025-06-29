{ { flutter_js } }
// Flutter 3.5+ compatible loader
// This file provides Flutter web initialization and configuration

'use strict';

(function () {
    // Ensure Flutter namespace exists
    window._flutter = window._flutter || {};

    // Set build configuration if not already set
    window._flutter.buildConfig = window._flutter.buildConfig || {
        engineRevision: 'stable',
        builds: [
            {
                compileTarget: 'dart2js',
                renderer: 'canvaskit',
                mainModule: 'main'
            }
        ]
    };

    // Flutter loader implementation
    window._flutter.loader = window._flutter.loader || {
        load: function (config) {
            config = config || {};

            return new Promise(function (resolve, reject) {
                // Configure service worker
                if (config.serviceWorker) {
                    if ('serviceWorker' in navigator) {
                        navigator.serviceWorker.register('flutter_service_worker.js')
                            .then(function (registration) {
                                console.log('ServiceWorker registration successful');
                            })
                            .catch(function (error) {
                                console.log('ServiceWorker registration failed:', error);
                            });
                    }
                }

                // Load main Dart module
                var scriptTag = document.createElement('script');
                scriptTag.src = 'main.dart.js';
                scriptTag.type = 'application/javascript';

                scriptTag.addEventListener('load', function () {
                    if (config.onEntrypointLoaded) {
                        // Provide engine initializer
                        var engineInitializer = {
                            initializeEngine: function (engineConfig) {
                                engineConfig = engineConfig || {};

                                return new Promise(function (engineResolve, engineReject) {
                                    // Wait for Flutter engine to be ready
                                    if (window._flutter && window._flutter.loader && window._flutter.loader.didCreateEngineInitializer) {
                                        var appRunner = {
                                            runApp: function () {
                                                // Initialize Flutter app
                                                if (window.main) {
                                                    window.main();
                                                } else {
                                                    console.error('Flutter main function not found');
                                                }
                                            }
                                        };
                                        engineResolve(appRunner);
                                    } else {
                                        // Fallback initialization
                                        setTimeout(function () {
                                            var appRunner = {
                                                runApp: function () {
                                                    if (window.main) {
                                                        window.main();
                                                    } else {
                                                        console.error('Flutter main function not found');
                                                    }
                                                }
                                            };
                                            engineResolve(appRunner);
                                        }, 100);
                                    }
                                });
                            }
                        };

                        config.onEntrypointLoaded(engineInitializer);
                    }

                    resolve();
                });

                scriptTag.addEventListener('error', function (e) {
                    console.error('Failed to load main.dart.js:', e);
                    reject(e);
                });

                document.head.appendChild(scriptTag);
            });
        }
    };

    // Compatibility aliases
    window.flutterLoader = window._flutter.loader;

})();
