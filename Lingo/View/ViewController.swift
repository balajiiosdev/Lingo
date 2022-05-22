//
//  ViewController.swift
//  Lingo
//
//  Created by Balaji V on 5/19/22.
//

import UIKit

class ViewController: UIViewController {
    private var gameViewModel: GameViewModelProtocol = GameViewModel()
    @IBOutlet weak var spanishLabel: UILabel!
    @IBOutlet weak var englishLabel: UILabel!
    @IBOutlet weak var correctCountLabel: UILabel!
    @IBOutlet weak var wrongCountLabel: UILabel!
    
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var wrongButton: UIButton!
    @IBOutlet weak var correctButton: UIButton!
    var challenge: Challenge?

    override func viewDidLoad() {
        super.viewDidLoad()
        gameViewModel.delegate = self
        startGame()
    }

    private func updateCorrectAttemptCount(_ count: Int) {
        correctCountLabel.text = "Correct attempts: \(count)"
    }

    private func updateWrongAttemptCount(_ count: Int) {
        wrongCountLabel.text = "Wrong attempts: \(count)"
    }

    private func startGame() {
        timerLabel.text = ""
        correctButton.isEnabled = true
        wrongButton.isEnabled = true
        updateCorrectAttemptCount(0)
        updateWrongAttemptCount(0)
        gameViewModel.startGame()
    }

    private func showGameOverAlert(score: Int) {
        correctButton.isEnabled = false
        wrongButton.isEnabled = false
        let alert = UIAlertController(title: "Game over!!", message: "Score: \(score)", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        let restart  = UIAlertAction(title: "Restart", style: .default) { [weak self]_ in
            self?.startGame()
        }
        alert.addAction(action)
        alert.addAction(restart)
        present(alert, animated: true, completion: nil)
    }

    @IBAction func didTapOnCorrect(_ sender: Any) {
        guard let challenge = challenge else {
            return
        }
        gameViewModel.chooseCorrect(for: challenge)
    }

    @IBAction func didTapOnWrong(_ sender: Any) {
        guard let challenge = challenge else {
            return
        }
        gameViewModel.chooseWrong(for: challenge)
    }

    private func loadChallenge(challenge: Challenge) {
        englishLabel.text  = challenge.english
        spanishLabel.text = challenge.spanish
        self.spanishLabel.alpha = 1.0
        self.challenge = challenge
    }

    private func animateChallenge() {
        UIView.animate(withDuration: 5.0, delay: 1.0, options: .curveLinear) { [weak self] in
            self?.spanishLabel.alpha = 0.0
        }
    }
}

extension ViewController: GameDelegate {
    func nextQuestion() {
        gameViewModel.loadChallenge { [weak self] challenge in
            self?.loadChallenge(challenge: challenge)
            self?.animateChallenge()
        }
    }

    func updateScore(score: Score) {
        updateCorrectAttemptCount(score.correctCount)
        updateWrongAttemptCount(score.wrongCount)
    }

    func gameOver(finalScore: Score) {
        showGameOverAlert(score: finalScore.correctCount)
    }

    func updateGameTime(text: String) {
        timerLabel.text = text
    }
}
