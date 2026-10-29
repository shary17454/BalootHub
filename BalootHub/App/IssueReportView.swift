import SwiftUI
import MessageUI

extension Notification.Name {
    static let balootIssueReportRequested = Notification.Name("balootIssueReportRequested")
}

/// Shake events travel through UIKit's responder chain to the app delegate.
/// No continuous accelerometer polling or background motion work is needed.
final class ShakeReportAppDelegate: UIResponder, UIApplicationDelegate {
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .balootIssueReportRequested, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}

@MainActor
enum IssueReportCapture {
    static func screenshot() -> UIImage? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = scenes
            .filter({ $0.activationState == .foregroundActive })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else { return nil }

        return UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }
}

enum IssueReportContent {
    static let recipient = "sharyalhwaid@gmail.com"

    static func subject(version: String) -> String {
        "بلاغ من تطبيق البلوت \(version)"
    }

    static func body(details: String, version: String, systemVersion: String) -> String {
        """
        وصف المشكلة:
        \(details.trimmingCharacters(in: .whitespacesAndNewlines))

        التطبيق: البلوت \(version)
        النظام: iOS \(systemVersion)
        """
    }
}

struct IssueReportView: View {
    let screenshot: UIImage?

    @Environment(\.dismiss) private var dismiss
    @State private var details = ""
    @State private var includesScreenshot = true
    @State private var showsMail = false
    @State private var showsShare = false
    @State private var mailStatus: String?

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(short) (\(build))"
    }

    private var message: String {
        IssueReportContent.body(details: details, version: version,
                                systemVersion: UIDevice.current.systemVersion)
    }

    private var attachment: UIImage? { includesScreenshot ? screenshot : nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("ما المشكلة؟") {
                    TextEditor(text: $details)
                        .frame(minHeight: 120)
                        .accessibilityIdentifier("issueReportDescription")
                    Text("اكتب ما حدث والخطوات التي أدت إليه. لا تُرسل أي بيانات تلقائيًا.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                if let screenshot {
                    Section("صورة الشاشة") {
                        Toggle("إرفاق صورة الشاشة", isOn: $includesScreenshot)
                            .accessibilityIdentifier("issueReportIncludeScreenshot")
                        Image(uiImage: screenshot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("معاينة صورة الشاشة الملتقطة عند فتح البلاغ")
                    }
                } else {
                    Section { Text("تعذر التقاط صورة الشاشة؛ يمكنك إرسال البلاغ نصيًا.") }
                }

                Section("الإرسال") {
                    LabeledContent("إلى", value: IssueReportContent.recipient)
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            showsMail = true
                        } else {
                            showsShare = true
                        }
                    } label: {
                        Label("متابعة إلى البريد", systemImage: "envelope")
                    }
                    .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("issueReportContinue")
                    Text("راجع النص والصورة قبل الإرسال. إن لم يكن البريد مُعدًا، اختر تطبيق بريد من قائمة المشاركة وأدخل العنوان الظاهر أعلاه.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .navigationTitle("الإبلاغ عن مشكلة")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("إلغاء") { dismiss() }
                }
            }
            .sheet(isPresented: $showsMail) {
                IssueMailComposer(body: message, screenshot: attachment) { result in
                    if result == .sent { mailStatus = "سُلّم البلاغ إلى تطبيق البريد. لا يعني هذا تأكيد وصوله إلى العنوان." }
                }
            }
            .sheet(isPresented: $showsShare) {
                IssueShareSheet(body: "إلى: \(IssueReportContent.recipient)\n\n\(message)", screenshot: attachment)
            }
            .alert("حالة البريد", isPresented: Binding(
                get: { mailStatus != nil },
                set: { if !$0 { mailStatus = nil } }
            )) {
                Button("حسنًا") { mailStatus = nil }
            } message: {
                Text(mailStatus ?? "")
            }
        }
    }
}

private struct IssueMailComposer: UIViewControllerRepresentable {
    let body: String
    let screenshot: UIImage?
    let onFinish: (MFMailComposeResult) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([IssueReportContent.recipient])
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        controller.setSubject(IssueReportContent.subject(version: version))
        controller.setMessageBody(body, isHTML: false)
        if let data = screenshot?.pngData() {
            controller.addAttachmentData(data, mimeType: "image/png", fileName: "baloot-report.png")
        }
        return controller
    }

    func updateUIViewController(_ controller: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss, onFinish: onFinish) }

    @MainActor final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        let onFinish: (MFMailComposeResult) -> Void

        init(dismiss: DismissAction, onFinish: @escaping (MFMailComposeResult) -> Void) {
            self.dismiss = dismiss
            self.onFinish = onFinish
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
            onFinish(result)
        }
    }
}

private struct IssueShareSheet: UIViewControllerRepresentable {
    let body: String
    let screenshot: UIImage?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [body]
        if let screenshot { items.append(screenshot) }
        return UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
