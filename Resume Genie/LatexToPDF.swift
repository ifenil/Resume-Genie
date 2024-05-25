import SwiftUI

struct ResumeFormView: View {
    @State private var name: String = ""
    @State private var education: String = ""
    @State private var experience: String = ""
    @State private var projects: String = ""
    @State private var linkUserName: String = ""
    @State private var email: String = ""
    @State private var pnum: String = ""
    @State private var summary: String = ""
    @State private var skills: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Name", text: $name)
                    TextField("LinkedIn Username", text: $linkUserName)
                    TextField("Email", text: $email)
                    TextField("Phone Number", text: $pnum)
                }
                Section(header: Text("Summary")) {
                    TextField("Summary", text: $summary)
                }
                Section(header: Text("Skills")) {
                    TextField("Skills", text: $skills)
                }
                Section(header: Text("Education")) {
                    TextField("Education", text: $education)
                }
                Section(header: Text("Experience")) {
                    TextField("Experience", text: $experience)
                }
                Section(header: Text("Projects")) {
                    TextField("Projects", text: $projects)
                }
            }
            .navigationBarTitle("Resume Genie")
            .navigationBarItems(trailing: Button(action: {
                generatePDF()
            }) {
                Text("Generate PDF")
            })
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    func generatePDF() {
        guard let latexContent = loadAndModifyTemplate(name: name, education: education, experience: experience, projects: projects, linkUserName: linkUserName, email: email, pnum: pnum, summary: summary, skills: skills) else {
            showError = true
            errorMessage = "Failed to load LaTeX template."
            return
        }
        sendLatexToServer(latexContent: latexContent)
    }
    
    func loadAndModifyTemplate(name: String, education: String, experience: String, projects: String, linkUserName: String, email: String, pnum: String, summary: String, skills: String) -> String? {
        guard let templatePath = Bundle.main.path(forResource: "cv", ofType: "tex") else {
            return nil
        }
        
        do {
            var template = try String(contentsOfFile: templatePath, encoding: .utf8)
            template = template.replacingOccurrences(of: "<<NAME>>", with: name)
            template = template.replacingOccurrences(of: "<<LINKUSERNAME>>", with: linkUserName)
            template = template.replacingOccurrences(of: "<<EMAIL>>", with: email)
            template = template.replacingOccurrences(of: "<<PNUM>>", with: pnum)
            template = template.replacingOccurrences(of: "<<SUMMARY>>", with: summary)
            template = template.replacingOccurrences(of: "<<SKILLS>>", with: skills)
            template = template.replacingOccurrences(of: "<<EDUCATION>>", with: education)
            template = template.replacingOccurrences(of: "<<EXPERIENCE>>", with: experience)
            template = template.replacingOccurrences(of: "<<PROJECTS>>", with: projects)
            return template
        } catch {
            print("Failed to load or modify template: \(error.localizedDescription)")
            return nil
        }
    }
    
    func sendLatexToServer(latexContent: String) {
        guard let url = URL(string: "https://nodeserver-jby0.onrender.com/convert") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = latexContent.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Failed to connect to the server: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "No data received from server."
                }
                return
            }
            
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
            let pdfURL = documentsDirectory.appendingPathComponent("resume.pdf")
            
            do {
                try data.write(to: pdfURL)
                presentPDF(at: pdfURL)
            } catch {
                DispatchQueue.main.async {
                    showError = true
                    errorMessage = "Failed to save PDF: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func presentPDF(at url: URL) {
        let documentInteractionController = UIDocumentInteractionController(url: url)
        DispatchQueue.main.async {
            documentInteractionController.delegate = UIApplication.shared.windows.first?.rootViewController as? UIDocumentInteractionControllerDelegate
            documentInteractionController.presentPreview(animated: true)
        }
    }
}

extension UIResponder: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
}
