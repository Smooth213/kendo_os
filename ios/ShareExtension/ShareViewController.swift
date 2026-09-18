import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        handleSharedContent()
    }

    private func handleSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        let textContentType = UTType.plainText.identifier

        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(textContentType) {
                provider.loadItem(forTypeIdentifier: textContentType, options: nil) { [weak self] (item, error) in
                    if let text = item as? String {
                        self?.openHostApp(with: text)
                    } else {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    }
                }
                return
            }
        }

        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func openHostApp(with text: String) {
        guard let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "kendoos://import-share?text=\(encodedText)") else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url, options: [:]) { [weak self] _ in
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }
                return
            }
            responder = responder?.next
        }

        // Fallback using selector
        let selector = sel_registerName("openURL:")
        var currentResponder: UIResponder? = self
        while let next = currentResponder?.next {
            if next.responds(to: selector) {
                next.perform(selector, with: url)
                break
            }
            currentResponder = next
        }
        self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
}
