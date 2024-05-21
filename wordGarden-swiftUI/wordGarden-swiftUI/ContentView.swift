////
////  ContentView.swift
////  wordGarden-swiftUI
////
////  Created by Wang, Alyssa on 2/28/24.
////
//
import SwiftUI
import AVFAudio
struct ContentView: View {
    @State private var wordsGuessed = 0
    @State private var wordsMissed = 0
    @State private var currentWordIndex = 0
    @State private var wordToGuess = ""
    @State private var revealedWord = ""
    @State private var lettersGuessed = ""
    @State private var guessesRemaining = 8
    @State private var imgName = "flower8"
    
    @State private var gameStatusMsg = "How Many Guesses to Uncover the Hidden Word?"
    @State private var guessedLetter = ""
    @State private var playAgainHidden = true
    @State private var playAgainButtonLabel = "Another Word?"
    @State private var audioPlayer: AVAudioPlayer!
    
    @FocusState private var textFieldIsFocused: Bool

    private let wordsToGuess = ["POTATO", "CAKE", "STARS", "MOON"]
    private let maxGuesses = 8
    var body: some View {
        VStack {
            HStack{
                VStack(alignment: .leading){
                    Text("Words Guessed: \(wordsGuessed)")
                    Text("Words Missed: \(wordsMissed)")
                }
                Spacer()
                VStack(alignment: .trailing){
                    Text("Words to Guess: \(wordsToGuess.count - (wordsGuessed + wordsMissed))")
                    Text("Words in Game: \(wordsToGuess.count)")
                }
            }
            .padding(.horizontal)
            Spacer()
            
            Text(gameStatusMsg)
                .font(.title)
                .multilineTextAlignment(.center)
                .frame(height: 80)
                .minimumScaleFactor(0.5)
                .padding()
            
            Spacer()
            
            //TODO: switch to wordsToGuess[currentWord]
            
            Text(revealedWord)
                .font(.title)
            
            
            if playAgainHidden{
                HStack{
                    TextField("", text: $guessedLetter)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 30)
                        .overlay{
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.gray, lineWidth: 2)
                        }
                        .keyboardType(.asciiCapable)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.characters)
                        .onChange(of: guessedLetter){ _ in
                            guessedLetter = guessedLetter.trimmingCharacters(in: .letters.inverted)
                            guard let lastChar = guessedLetter.last
                            else{
                                return
                            }
                            guessedLetter = String(lastChar).uppercased()
                        }
                        .onSubmit {
                            guard guessedLetter != "" else{
                                return
                            }
                            guessALetter()
                        }
                        .focused($textFieldIsFocused)
                    
                    Button("Guess a Letter"){
                        guessALetter()
                        updateGamePlay()
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(guessedLetter.isEmpty)
                }
            }else{
                Button(playAgainButtonLabel){
                    // If all words have been guessed...
                    if currentWordIndex == wordToGuess.count {
                        currentWordIndex = 0
                        wordsGuessed = 0
                        wordsMissed = 0
                        playAgainButtonLabel = "Another Word?"
                    }
                    // Reset after a word was guessed or missed
                    wordToGuess = wordsToGuess[currentWordIndex]
                    revealedWord = "_" + String(String(repeating: " _", count: wordToGuess.count-1))
                    lettersGuessed = ""
                    guessesRemaining = maxGuesses
                    imgName = "flower\(guessesRemaining)"
                    gameStatusMsg = "How Many Guesses to Uncover the Hidden Word?"
                    playAgainHidden = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            }
        
            
            Spacer()
            
            Image(imgName)
                .resizable()
                .scaledToFit()
                .animation(.easeIn(duration: 0.75), value: imgName)
            
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear(){
            wordToGuess = wordsToGuess[currentWordIndex]
            revealedWord = "_" + String(String(repeating: " _", count: wordToGuess.count-1))
            guessesRemaining = maxGuesses
        }
        
        
    }
    func guessALetter(){
        textFieldIsFocused = false
        lettersGuessed = lettersGuessed + guessedLetter
        
        revealedWord = ""
        //loop through all letters in lettersGuessed
        for letter in wordToGuess {
            if lettersGuessed.contains(letter){
                revealedWord = revealedWord + "\(letter) "
            } else {
                // if not, add an underscore + a blank space to revealedWord
                revealedWord = revealedWord + "_ "
            }
        }
        revealedWord.removeLast()
    
    }
    
    func updateGamePlay(){
        
        if !wordToGuess.contains(guessedLetter){
            guessesRemaining -= 1
            // animate crumbing leaf and play "incorrect" sound
            imgName = "wilt\(guessesRemaining)"
            playSound(soundName: "incorrect")
            
            //Delay change to flower image until after wilt is done
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75){
                imgName = "flower\(guessesRemaining)"
            }
        } else {
            playSound(soundName: "correct")
        }
        
        if !revealedWord.contains("_"){ // Guessed correctly when no _ in revealedWord
            gameStatusMsg = "You've Guessed It! It Took You \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es") to Guess the Word."
            wordsGuessed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-guessed")
        } else if guessesRemaining == 0 { // Word Missed
            gameStatusMsg = "Sorry. You're All Out Of Guesses :("
            wordsMissed += 1
            currentWordIndex += 1
            playAgainHidden = false
            playSound(soundName: "word-not-guessed")
        } else { // Keep guessing
            gameStatusMsg = "You've Made \(lettersGuessed.count) Guess\(lettersGuessed.count == 1 ? "" : "es")"
        }
        
        if currentWordIndex == wordsToGuess.count {
            playAgainButtonLabel = "Restart Game?"
            gameStatusMsg = gameStatusMsg + "\nYou've Tried All of the Words. Restart from the Beginning?"
        }
        
        guessedLetter = ""
    }
    
    func playSound(soundName: String){
        guard let soundFile = NSDataAsset(name: soundName) else {
            print("😡 Count not read file named \(soundName)")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(data: soundFile.data)
            audioPlayer.play()
        } catch {
            print("😡 ERROR: \(error.localizedDescription) creating audioPlayer.")
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

