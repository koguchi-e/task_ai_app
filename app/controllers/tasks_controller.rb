class TasksController < ApplicationController
  def index
  end

  def create
    prompt = <<~PROMPT
      あなたはユーザーが入力した状況、問題、目標を元に
      次に行う小さいタスクを作成してください。

      ユーザーを分析したり説教したりしません。

      目的は、
      「考えすぎて止まっている人」が
      次の小さい行動に移れるよう支援することです。

      以下ルールを守ってください。

      - 医療的判断をしない
      - 人生アドバイスをしない
      - タスクだけ出力してください
        - 長文を書かない
        - 原因分析をしない
        - 励ましは書かない
      - タスクは5〜15分で終わるサイズ
      - 抽象的な表現を避ける
      - 「学ぶ」「理解する」「動くではなく具体的に何をすべきかを書く
      - 簡単で優先度の高い順に出す
      - 「今すぐやること」は出力しない

      入力形式：
      状況:
      #{params[:situation]}

      問題:
      #{params[:problem]}

      目標:
      #{params[:goal]}

      出力形式：
      1.
      2.
      3.
      4.
      5.
    PROMPT

    response = Faraday.post(url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.body = {
        contents: [
          {
            parts: [
              {
                text: prompt
              }
            ]
          }
        ]
      }.to_json
    end

    json = JSON.parse(response.body)

    @result =
      json.dig(
        "candidates",
        0,
        "content",
        "parts",
        0,
        "text"
      )
    
    TaskLog.create(
      situation: params[:situation],
      problem: params[:problem],
      goal: params[:goal],
      result: @result
    )

    Rails.logger.debug @result
    
    render :result
  end

  private

  def url
    api_key = ENV['GEMINI_API_KEY']

    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}"
  end
end
