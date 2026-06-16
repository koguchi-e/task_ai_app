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

      - タスクは5つだけ出力し、箇条書きなどにはしないでください。
      - 医療的判断をしないでください
      - 人生アドバイスをしないでください
      - タスクだけ出力してください
        - 長文を書かないでください
        - 原因分析をしないでください
        - 励ましは書かないでください
      - タスクは5〜15分で終わるサイズ
      - 必要な場合は、〇回・〇分・〇時など、具体的な回数や時刻も入れてください
      - 「学ぶ」「理解する」「動く」など抽象的な表現を避け、具体的に何をすべきかを書く
      - タスクはユーザーが入れ替えることができるので、「次に」「最後に」など順番を意識させる接続詞はつけないでください
      - 簡単で優先度の高い順に出してください
      - タスクは1つずつ改行して出力してください

      入力形式：
      状況:
      #{params[:situation]}

      問題:
      #{params[:problem]}

      目標:
      #{params[:goal]}
    PROMPT

    # Gemini
    gemini_start =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

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

    @tasks = @result.to_s.split("\n")

    @gemini_elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - gemini_start

    # GPT
    gpt_start =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    client = OpenAI::Client.new(
      access_token:
        Rails.application
            .credentials
            .openai[:api_key],
        log_errors: true
    )

    response = client.responses.create(
      parameters: {
        model: "gpt-4o-mini",
        input: prompt
      }
    )

    @gpt_result =
      response.dig(
        "output",
        0,
        "content",
        0,
        "text"
      )

    @gpt_tasks =
      @gpt_result
        .to_s
        .lines
        .map(&:strip)
        .reject(&:blank?)

    @gpt_elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - gpt_start

    # claude
    claude_start =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      )

    client = Anthropic::Client.new(
      api_key:
        Rails.application
            .credentials
            .anthropic[:api_key]
    )

    response =
      client.messages.create(
        model: "claude-haiku-4-5",
        max_tokens: 1000,
        messages: [
          {
            role: "user",
            content: prompt
          }
        ]
      )

    @claude_elapsed =
      Process.clock_gettime(
        Process::CLOCK_MONOTONIC
      ) - claude_start

    @claude_result =
      response.content.first.text

    @claude_tasks =
      @claude_result
        .lines
        .map(&:strip)
        .reject(&:blank?)

    Rails.logger.debug @result
    
    render :result
  end

  def download_json
    data = {
      input: {
        situation: params[:situation],
        problem: params[:problem],
        goal: params[:goal]
      },
      results: {
        gemini: {
          elapsed: params[:gemini_elapsed],
          text: params[:gemini_result]
        },
        gpt: {
          elapsed: params[:gpt_elapsed],
          text: params[:gpt_result]
        },
        claude: {
          elapsed: params[:claude_elapsed],
          text: params[:claude_result]
        }
      }
    }

    send_data(
      JSON.pretty_generate(data),
      filename: "ai_comparison_result.json",
      type: "application/json",
      disposition: "attachment"
    )
  end

  private

  def url
    api_key = ENV['GEMINI_API_KEY']

    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=#{api_key}"
  end
end
