//
//  MajorView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

let majors = ["Aerospace Engineering ", "African American Studies ", "Agricultural and Resource Economics ", "Air Force ROTC AFROTC", "American Cultures ", "American Studies ", "Ancient Greek & Roman Studies, Department of ", "Ancient History and Mediterranean Archaeology ", "Anthropology ", "Applied Science and Technology Graduate Group ", "Architecture ", "Army ROTC", "Art History ", "Art Practice ", "Arts & Humanities, College of Letters & Science Division ", "Asian American and Asian Diaspora Studies ", "Asian Studies ", "Astronomy ", "Berkeley Global Executive Education ", "Biochemistry, Comparative ", "Bioengineering ", "Biological Sciences, College of Letters and Science Division of ", "Biology, Integrative ", "Biology, Molecular and Cell ", "Biology, Plant and Microbial ", "Biophysics ", "Biostatistics ", "Buddhist Studies ", "Business ", "Canadian Studies Program ", "Celtic Studies ", "Chemical and Biomolecular Engineering, Department of ", "Chemistry, College of ", "Chemistry, Department of ", "Chicanx Latinx Studies ", "Chinese Studies, Center for ", "City and Regional Planning ", "Civil and Environmental Engineering ", "Cognitive Science ", "College Writing Programs ", "Comparative Biochemistry ", "Comparative Literature ", "Computational and Genomic Biology Graduate Program ", "Computational Social Science ", "Computer Science ", "Computing, Data Science, and Society, College of ", "Conservation Resource Studies ", "Continuing Education UC Berkeley Extension", "Creative Writing ", "Critical Theory, The Program in ", "Dance ", "Demography ", "Development Practice ", "Disability Studies ", "Dutch Studies ", "Earth and Planetary Science ", "East Asian Languages & Cultures ", "East Asian Studies ", "Economics ", "Economics, Agricultural and Resource ", "Economics, Law & ", "Education, Berkeley School of ", "Endocrinology ", "Energy and Resources Group ", "Engineering Science ", "Engineering, Chemical and Biomolecular ", "Engineering, College of ", "English ", "Environmental Design, College of ", "Environmental Economics and Policy ", "Environmental Health Sciences ", "Environmental Planning, Landscape Architecture and ", "Environmental Science, Policy, and Management ", "Environmental Sciences, College of Natural Resources ", "Ethnic Studies ", "European Studies ", "Extension, UC Berkeley ", "Fall Program for Freshmen ", "Film & Media ", "Folklore ", "Forestry, Center for ", "French ", "Gender and Women's Studies ", "Genetics and Plant Biology ", "Geography ", "German ", "Global Studies ", "Haas School of Business ", "Health Policy ", "Health Sciences, Environmental ", "History ", "History of Art ", "Human Rights Interdisciplinary Minor ", "Industrial Engineering and Operations Research ", "Infectious Diseases and Immunity ", "Information, School of (iSchool) ", "Integrative Biology ", "Interdisciplinary Studies ", "Italian Studies ", "Jewish Studies Program ", "Journalism, Graduate School of ", "Jurisprudence and Social Policy Program ", "Landscape Architecture and Environmental Planning ", "Law ", "Law & Economics Program ", "Legal Studies ", "Letters & Science ", "Linguistics ", "Logic and the Methodology of Science ", "Materials Science and Engineering ", "Mathematical and Physical Sciences, College of Letters & Science Division ", "Mathematics ", "Mechanical Engineering ", "Media Studies ", "Medical Program (Joint UCB-UCSF) ", "Medieval Studies ", "Mediterranean Archaeology, Ancient History and ", "Microbial Biology, Plant and ", "Microbiology, Graduate Group in ", "Middle Eastern Languages and Cultures, Department of ", "Middle Eastern Studies ", "Military Science (ROTC) ", "Molecular and Cell Biology ", "Molecular Environmental Biology ", "Molecular Toxicology (Graduate) ", "Molecular Toxicology (Undergraduate) ", "Music, Department of ", "Native American Studies ", "Natural Resources, College of ", "Naval Science (Navy ROTC) ", "Neurobiology ", "Neuroscience ", "New Media, Berkeley Center for ", "Nuclear Engineering ", "Nutrition/Nutritional Sciences ", "Ocean Engineering ", "Operations Research, Industrial Engineering and ", "Optometry, School of ", "Philosophy ", "Physical Education ", "Physics ", "Plant and Microbial Biology ", "Policy Analysis, Health Services and ", "Political Economy ", "Political Science ", "Portuguese, Spanish and ", "Psychology ", "Public Affairs, Masters of (MPA) ", "Public Health ", "Public Policy, The Richard & Rhoda Goldman School of ", "Rangeland and Wildlife Management ", "Renaissance and Early Modern Studies ", "Rhetoric ", "Romance Languages and Literatures ", "ROTC (Air Force) ", "ROTC (Army) ", "ROTC (Navy) ", "Scandinavian ", "Science and Mathematics Education, Graduate Group (SESAME) ", "Science and Technology, Applied ", "Slavic Languages and Literatures ", "Slavic, East European, and Eurasian Studies, Institute of ", "Social Welfare, School of ", "Society and Environment ", "Sociology ", "Sociology and Demography, Graduate Group in ", "South and Southeast Asian Studies ", "South Asia Studies, Institute for ", "Spanish and Portuguese ", "Statistics ", "Theater, Dance & Performance Studies ", "Toxicology, Nutritional Science and ", "Undergraduate Studies, College of Letters & Science ", "Urban Design ", "Vision Science ", "Women's Studies, Gender and"]

struct MajorView: View {
    @Environment(Model.self) var model

    @State private var major = majors.first!

    private func onContinue() {
        model.auth.localUser?.major = major
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                FadingText("What's your major?")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()

                FadingText("All majors at UC Berkeley are listed below in alphabetical order.")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .opacity(0.75)

                Spacer()

                Picker("Major", selection: $major) {
                    ForEach(majors, id: \.self) { major in
                        Text(major)
                            .tag(major)
                    }
                }
                .pickerStyle(.wheel)
                .foregroundColor(.white)

                Spacer()

                RoundedButton("Continue") {
                    onContinue()
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    MajorView()
}
