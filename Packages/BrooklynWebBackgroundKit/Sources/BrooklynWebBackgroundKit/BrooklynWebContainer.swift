#if os(iOS)
import OSLog
import SwiftUI
import UIKit
import WebKit

struct BrooklynWebContainer: UIViewRepresentable {
    let isActive: Bool
    let configuration: BrooklynWebConfiguration
    let telemetryDurationMS: Int?

    func makeCoordinator() -> Coordinator {
        Coordinator(
            telemetryDurationMS: telemetryDurationMS,
            highRefreshEnabled: BrooklynWebHighRefreshRequest.isEnabled()
        )
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: Coordinator.lifecycleHandler)
        contentController.add(context.coordinator, name: Coordinator.telemetryHandler)
        #if DEBUG
        if context.coordinator.shouldBootstrapHighRefresh {
            contentController.addUserScript(WKUserScript(
                source: "window.__brooklynInitialHighRefresh = true;",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }
        #endif

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        webConfiguration.websiteDataStore = .nonPersistent()
        webConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        webConfiguration.suppressesIncrementalRendering = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.underPageBackgroundColor = .black
        webView.isUserInteractionEnabled = false
        webView.allowsBackForwardNavigationGestures = false
        webView.allowsLinkPreview = false
        webView.scrollView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.panGestureRecognizer.isEnabled = false
        webView.scrollView.pinchGestureRecognizer?.isEnabled = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.attach(
            webView: webView,
            isActive: isActive,
            configuration: configuration
        )
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.setActive(isActive)
        context.coordinator.setConfiguration(configuration)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.detach()
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.lifecycleHandler
        )
        webView.configuration.userContentController.removeScriptMessageHandler(
            forName: Coordinator.telemetryHandler
        )
        webView.navigationDelegate = nil
        webView.stopLoading()
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        static let lifecycleHandler = "brooklynLifecycle"
        static let telemetryHandler = "brooklynTelemetry"

        private static let logger = Logger(
            subsystem: "BrooklynWebBackgroundKit",
            category: "WebView"
        )

        private weak var webView: WKWebView?
        private var distributionRoot: URL?
        private var isActive = false
        private var configuration: BrooklynWebConfiguration = .default
        private var lastSentConfiguration: BrooklynWebConfiguration?
        private var isBridgeReady = false
        private var didStartTelemetry = false
        private var previousIdleTimerDisabled: Bool?
        private let telemetryDurationMS: Int?
        private let highRefreshEnabled: Bool
        #if DEBUG
        private var highRefreshDriver: BrooklynWebHighRefreshDriver?
        var shouldBootstrapHighRefresh: Bool { highRefreshEnabled }
        #endif

        init(telemetryDurationMS: Int?, highRefreshEnabled: Bool) {
            self.telemetryDurationMS = telemetryDurationMS
            self.highRefreshEnabled = highRefreshEnabled
        }

        func attach(
            webView: WKWebView,
            isActive: Bool,
            configuration: BrooklynWebConfiguration
        ) {
            self.webView = webView
            self.isActive = isActive
            self.configuration = configuration
            #if DEBUG
            if highRefreshEnabled {
                let driver = BrooklynWebHighRefreshDriver(
                    webView: webView,
                    hostActive: isActive
                )
                driver.start()
                highRefreshDriver = driver
            }
            #endif
            do {
                let resources = try BrooklynWebResources.entryPoint()
                distributionRoot = resources.root
                webView.loadFileURL(
                    resources.index,
                    allowingReadAccessTo: resources.root
                )
            } catch {
                Self.logger.error(
                    "Local WebDist unavailable: \(String(describing: error), privacy: .public)"
                )
            }
        }

        func detach() {
            restoreIdleTimer()
            #if DEBUG
            highRefreshDriver?.stop()
            highRefreshDriver = nil
            #endif
            isBridgeReady = false
            lastSentConfiguration = nil
            webView = nil
        }

        func setActive(_ active: Bool) {
            isActive = active
            #if DEBUG
            highRefreshDriver?.setHostActive(active)
            #endif
            guard isBridgeReady else { return }
            evaluate("window.__brooklynSetActive?.(\(active ? "true" : "false"));")
        }

        func setConfiguration(_ configuration: BrooklynWebConfiguration) {
            self.configuration = configuration
            guard isBridgeReady, lastSentConfiguration != configuration else { return }
            do {
                let data = try JSONEncoder().encode(configuration)
                let payload = String(decoding: data, as: UTF8.self)
                lastSentConfiguration = configuration
                evaluate("window.__brooklynSetAppearance?.(\(payload));")
            } catch {
                Self.logger.error(
                    "Appearance payload failed: \(String(describing: error), privacy: .public)"
                )
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            guard let distributionRoot else {
                decisionHandler(.cancel)
                return
            }
            decisionHandler(
                BrooklynWebNavigationPolicy.allows(
                    navigationAction.request.url,
                    inside: distributionRoot
                ) ? .allow : .cancel
            )
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            isBridgeReady = false
            lastSentConfiguration = nil
            didStartTelemetry = false
            #if DEBUG
            highRefreshDriver?.cancelTelemetry()
            #endif
            restoreIdleTimer()
            guard isActive,
                  let distributionRoot,
                  let index = try? BrooklynWebResources.entryPoint().index
            else { return }
            webView.loadFileURL(index, allowingReadAccessTo: distributionRoot)
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case Self.lifecycleHandler:
                handleLifecycle(message.body)
            case Self.telemetryHandler:
                handleTelemetry(message.body)
            default:
                break
            }
        }

        private func handleLifecycle(_ messageBody: Any) {
            guard let message = messageBody as? [String: Any],
                  message["kind"] as? String == "ready"
            else { return }
            isBridgeReady = true
            lastSentConfiguration = nil
            setConfiguration(configuration)
            evaluate(
                "window.__brooklynSetHighRefresh?.(\(highRefreshEnabled ? "true" : "false"));"
            )
            setActive(isActive)
            startTelemetryIfRequested()
        }

        private func startTelemetryIfRequested() {
            guard let telemetryDurationMS, !didStartTelemetry else { return }
            didStartTelemetry = true
            previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
            UIApplication.shared.isIdleTimerDisabled = true
            #if DEBUG
            highRefreshDriver?.beginTelemetry()
            #endif
            evaluate("window.__brooklynStartTelemetry?.(\(telemetryDurationMS));")
        }

        private func handleTelemetry(_ messageBody: Any) {
            do {
                var telemetryBody = messageBody
                #if DEBUG
                if var dictionary = messageBody as? [String: Any],
                   let highRefreshDriver {
                    for (key, value) in highRefreshDriver.finishTelemetry() {
                        dictionary[key] = value
                    }
                    telemetryBody = dictionary
                }
                #endif
                let report = try BrooklynWebTelemetryStore.decode(
                    messageBody: telemetryBody
                )
                try BrooklynWebTelemetryStore.persist(report)
            } catch {
                Self.logger.error(
                    "Telemetry message rejected: \(String(describing: error), privacy: .public)"
                )
            }
            restoreIdleTimer()
        }

        private func restoreIdleTimer() {
            guard let previousIdleTimerDisabled else { return }
            UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled
            self.previousIdleTimerDisabled = nil
        }

        private func evaluate(_ script: String) {
            webView?.evaluateJavaScript(script) { _, error in
                if let error {
                    Self.logger.error(
                        "JavaScript bridge failed: \(String(describing: error), privacy: .public)"
                    )
                }
            }
        }
    }
}
#endif
