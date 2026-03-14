class AltchaController < ApplicationController
  allow_unauthenticated_access
  skip_verify_authorized

  def new
    options = Altcha::ChallengeOptions.new(hmac_key:, max_number: 100_000)
    challenge = Altcha.create_challenge(options)

    render(json: challenge.as_json)
  end

  private

  def hmac_key
    AppConfig.altcha_hmac_key!
  end
end
