import Foundation

/// Population-derived priors for cycle length, per cycle mode.
/// Sources: Symul & Holmes (2021) on 500K-user Clue dataset; Bortot et al. (2012) Bayesian fecundity models.
/// Numbers here are conservative central tendencies, refined as Astera collects (private, on-device) evidence.
struct CycleLengthPrior: Equatable {
    /// Prior mean cycle length (days).
    let mean: Double
    /// Prior standard deviation of the *mean* itself. How confident we are in `mean`.
    let meanStdDev: Double
    /// Population-level standard deviation of cycle lengths. How variable cycles are for this mode.
    let observationStdDev: Double
    /// Equivalent prior sample size. How many "ghost" observations the prior is worth.
    let strength: Double

    static func forMode(_ mode: CycleMode) -> CycleLengthPrior {
        switch mode {
        case .regular:
            return CycleLengthPrior(mean: 28.0, meanStdDev: 2.0, observationStdDev: 2.0, strength: 3.0)
        case .notSure:
            return CycleLengthPrior(mean: 28.0, meanStdDev: 3.0, observationStdDev: 4.0, strength: 2.0)
        case .irregular:
            return CycleLengthPrior(mean: 30.0, meanStdDev: 5.0, observationStdDev: 6.0, strength: 2.0)
        case .pcos:
            return CycleLengthPrior(mean: 35.0, meanStdDev: 8.0, observationStdDev: 9.0, strength: 1.5)
        case .endometriosis:
            // Endo cycles are often more painful, sometimes longer; treat similarly to irregular but acknowledge variance.
            return CycleLengthPrior(mean: 29.0, meanStdDev: 5.0, observationStdDev: 6.0, strength: 1.8)
        case .iud:
            return CycleLengthPrior(mean: 28.0, meanStdDev: 4.0, observationStdDev: 5.0, strength: 2.0)
        case .hormonalBC:
            // Hormonal BC produces withdrawal bleeds (combined pill) or absent bleeds (mini-pill, implant).
            // Treat like IUD with slightly looser bounds; mode-specific UI handles "absent bleeds are normal" framing.
            return CycleLengthPrior(mean: 28.0, meanStdDev: 4.0, observationStdDev: 5.0, strength: 2.0)
        case .perimenopause:
            return CycleLengthPrior(mean: 30.0, meanStdDev: 6.0, observationStdDev: 8.0, strength: 1.5)
        case .ttc:
            return CycleLengthPrior(mean: 28.0, meanStdDev: 2.5, observationStdDev: 3.0, strength: 2.5)
        case .pregnant, .postpartum, .postLoss, .surgicalMenopause, .trackingOnT:
            // These modes don't predict periods; we still return a placeholder so the predictor never crashes
            // if it gets called before the UI has gated it.
            return CycleLengthPrior(mean: 28.0, meanStdDev: 5.0, observationStdDev: 5.0, strength: 1.0)
        }
    }
}
