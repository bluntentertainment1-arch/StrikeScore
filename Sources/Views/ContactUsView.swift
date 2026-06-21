import SwiftUI
import MessageUI

struct ContactUsView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Your Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }

                Section("Message") {
                    TextField("Subject", text: $subject)
                    TextEditor(text: $message)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Send Message") {
                        sendMessage()
                    }
                    .disabled(name.isEmpty || email.isEmpty || subject.isEmpty || message.isEmpty)
                }

                Section("Direct Contact") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(AppConstants.contactEmail)
                            .foregroundColor(.green)
                    }

                    Button("Copy Email Address") {
                        UIPasteboard.general.string = AppConstants.contactEmail
                        alertMessage = "Email copied to clipboard"
                        showingAlert = true
                    }
                }
            }
            .navigationTitle("Contact Us")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Contact", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    to: AppConstants.contactEmail,
                    subject: subject,
                    body: "From: \(name) (\(email))\n\n\(message)"
                )
            }
        }
    }

    private func sendMessage() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            alertMessage = "Please set up Mail app or email us directly at \(AppConstants.contactEmail)"
            showingAlert = true
        }
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let to: String
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setToRecipients([to])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
