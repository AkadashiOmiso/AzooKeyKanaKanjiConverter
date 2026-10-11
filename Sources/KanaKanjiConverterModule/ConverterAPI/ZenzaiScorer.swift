//
//  ZenzaiScorer.swift
//  AzooKeyKanaKanjiConverter
//
//  yokiKana（推測修正）のために足したもの。本家にはない。
//

/// zenz で、読みに対する任意の候補の表記の対数確率を出す（yokiKana の推測修正。候補は辞書と文節で作り、zenz は並べるだけ）。
///
/// `KanaKanjiConverter.zenzaiScorer(options:)` で、変換器を使うスレッドで作る。作ったあとは、どのスレッドから呼んでもよい
/// （zenz の推論の鍵を取る。変換器が同時に zenz を使うときは、どちらかが待つ）
public struct ZenzaiScorer: @unchecked Sendable {
    let zenz: Zenz
    let versionDependentMode: ConvertRequestOptions.ZenzaiVersionDependentMode

    /// かなの読み `reading` に対する `candidates` それぞれの対数確率（候補のトークンと最後の EOS の log softmax の和）。
    /// 文脈は作ったときの options の versionDependentMode（左の文脈）。共通の頭のトークンを 1 回だけ計算する。計算できなければ nil
    public func logProbabilities(reading: String, candidates: [String]) -> [Float]? {
        self.zenz.logProbabilities(convertTarget: reading, candidates: candidates, versionDependentConfig: self.versionDependentMode)
    }

    /// `logProbabilities` と同じ値を、候補を 1 件ずつ decode して出す（確かめる用。遅い）
    public func referenceLogProbabilities(reading: String, candidates: [String]) -> [Float]? {
        self.zenz.logProbabilities(convertTarget: reading, candidates: candidates, versionDependentConfig: self.versionDependentMode,
                                   oneByOne: true)
    }
}

extension KanaKanjiConverter {
    /// `options` の Zenzai の重みと文脈で採点する `ZenzaiScorer`。Zenzai が無効か、モデルを読めなければ nil
    public func zenzaiScorer(options: ConvertRequestOptions) -> ZenzaiScorer? {
        guard options.zenzaiMode.enabled, let zenz = self.getModel(modelURL: options.zenzaiMode.weightURL) else {
            return nil
        }
        return ZenzaiScorer(zenz: zenz, versionDependentMode: options.zenzaiMode.versionDependentMode)
    }
}
