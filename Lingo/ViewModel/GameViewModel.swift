//
//  GameViewModel.swift
//  Lingo
//
//  Created by Balaji V on 5/19/22.
//

import Foundation

protocol GameDelegate: AnyObject {
    func nextQuestion()
    func updateScore(score: Score)
    func gameOver(finalScore: Score)
    func updateGameTime(text: String)
}

protocol GameViewModelProtocol {
    var delegate: GameDelegate? { get set }

    /// Start the Game
    func startGame()

    /// End the Game
    func endGame()

    /// Load new challenge
    func loadChallenge(completion: (Challenge) -> Void)

    /// User did choose correct for the challenge
    func chooseCorrect(for challenge: Challenge)

    /// User did choose wrong for the challenges
    func chooseWrong(for challenge: Challenge)
}

enum Constants {
    static let fileName = "words"
    static let maximumNumberOfQuestions = 15
    static let timeLimitInSeconds = 5
    static let maxWrongAnswers = 3
    static let correctness: Float = 0.25
}

class GameViewModel: GameViewModelProtocol {
    private var correctWordPairs: [WordPair] = []
    private var questions: [String: String] = [:]
    private var score = Score()
    private var timer: Timer?
    private var answeredQuestion = false
    private var timeInterval: Int = 0
    weak var delegate: GameDelegate?

    func startGame() {
        score = Score()
        DispatchQueue.global().async {[weak self] in
            guard let self = self else { return }
            self.loadGameData()
            DispatchQueue.main.async {
                self.delegate?.nextQuestion()
            }
        }
    }

    func loadChallenge(completion: (Challenge) -> Void) {
        guard let question = questions.randomElement() else {
            endGame()
            return
        }
        questions.removeValue(forKey: question.key)
        answeredQuestion = false
        timeInterval = 0
        timer = Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(updateGameTimer),
                                     userInfo: nil,
                                     repeats: true)
        completion(Challenge(english: question.key, spanish: question.value))
    }

    func chooseCorrect(for challenge: Challenge) {
        userDidAnswerQuestion()

        // Find the correct word pair for the given challenge
        let correctPair = correctWordPair(for: challenge)

        if correctPair?.spanish == challenge.spanish {
            score.correctCount += 1
        } else {
            score.wrongCount += 1
        }
        moveToNextQuestion()
    }

    func chooseWrong(for challenge: Challenge) {
        userDidAnswerQuestion()

        // Find the correct word pair for the given challenge
        let correctPair = correctWordPair(for: challenge)

        if correctPair?.spanish != challenge.spanish {
            score.correctCount += 1
        } else {
            score.wrongCount += 1
        }
        moveToNextQuestion()
    }

    func endGame() {
        delegate?.gameOver(finalScore: score)
        delegate?.updateGameTime(text: "")
        timeInterval = 0
        score.wrongCount = 0
        score.correctCount = 0
        timer?.invalidate()
    }

    // Shuffle questions and answers with specific correctness
    private func shuffleQuestions(questions: [String: String], correctness: Int) -> [String: String] {
        var questionsCopy = questions

        // Pick n number of correct word pairs
        var correctPair: [String: String] = [:]
        for _ in 0..<correctness {
            guard let pair = questions.randomElement() else { continue }
            correctPair[pair.key] = pair.value
            questionsCopy.removeValue(forKey: pair.key)
        }

        // shuffle the rest of the question's answers
        let shuffledAnswers = questionsCopy.values.shuffled()
        var shuffledQuestions: [String: String] = [:]
        for question in questionsCopy.keys.shuffled() {
            shuffledQuestions[question] = shuffledAnswers.randomElement()
        }

        // append the correct question answer pairs
        for pair in correctPair {
            shuffledQuestions[pair.key] = pair.value
        }

        return shuffledQuestions
    }

    @objc private func updateGameTimer() {
        timeInterval += 1
        delegate?.updateGameTime(text: "00:0\(timeInterval)")
        if timeInterval == Constants.timeLimitInSeconds {
            timer?.invalidate()
            delegate?.updateGameTime(text: "")
            if answeredQuestion == false {
                NSLog("Question unanswered. Update wrong count")
                score.wrongCount += 1
                delegate?.updateScore(score: score)
                delegate?.nextQuestion()
                if shouldEndGame() {
                    endGame()
                    return
                }
            }
        }
    }

    private func userDidAnswerQuestion() {
        answeredQuestion = true
        timer?.invalidate()
        delegate?.updateGameTime(text: "")
    }

    private func correctWordPair(for challenge: Challenge) -> WordPair? {
        let correctPair = correctWordPairs.first { pair in
            pair.english == challenge.english
        }
        return correctPair
    }

    private func moveToNextQuestion() {
        delegate?.updateScore(score: score)
        if shouldEndGame() {
            endGame()
            return
        }
        delegate?.nextQuestion()
    }

    private func shouldEndGame() -> Bool {
        let totalQuestionsAttempted = score.correctCount + score.wrongCount
        let maxQuestionsReached = (totalQuestionsAttempted > Constants.maximumNumberOfQuestions)
        return ((score.wrongCount == Constants.maxWrongAnswers) || maxQuestionsReached)
    }

    private func prepareQuestions(maxNumberOfQuestions: Int, correctness: Float) -> [String: String] {
        var questions: [String: String] = [:]
        // pick n number of questions from the pool
        var index = 0
        for wordPair in correctWordPairs.shuffled() {
            questions[wordPair.english] = wordPair.spanish
            index += 1
            if index == maxNumberOfQuestions {
                break
            }
        }
        let maxCorrectAnswers = Int(round(Float(maxNumberOfQuestions) * correctness))
        return shuffleQuestions(questions: questions, correctness: maxCorrectAnswers)
    }

    private func loadGameData() {
        guard let url = Bundle.main.url(forResource: Constants.fileName,
                                        withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            let jsonDecoder = JSONDecoder()
            correctWordPairs = try jsonDecoder.decode([WordPair].self, from: data)
            questions = prepareQuestions(maxNumberOfQuestions: Constants.maximumNumberOfQuestions,
                                         correctness: Constants.correctness)
        } catch (let error) {
            NSLog("Error  occured while loading  data \(error.localizedDescription)")
        }
    }
}
