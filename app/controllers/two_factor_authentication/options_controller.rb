module TwoFactorAuthentication
  class OptionsController < ApplicationController
    include TwoFactorAuthenticatable

    FACTOR_TO_URL_METHOD = {
      'voice' => :otp_send_url,
      'sms' => :otp_send_url,
      'phone' => :otp_send_url,
      'auth_app' => :login_two_factor_authenticator_url,
      'piv_cac' => :login_two_factor_piv_cac_url,
      'webauthn' => :login_two_factor_webauthn_url,
      'personal_key' => :login_two_factor_personal_key_url,
      'backup_code' => :login_two_factor_backup_code_url,
    }.freeze

    EXTRA_URL_OPTIONS = {
      'voice' => {
        otp_delivery_selection_form: { otp_delivery_preference: 'voice' },
      },
      'sms' => {
        otp_delivery_selection_form: { otp_delivery_preference: 'sms' },
      },
    }.freeze

    def index
      @two_factor_options_form = TwoFactorLoginOptionsForm.new(current_user)
      @presenter = two_factor_options_presenter
      analytics.track_event(Analytics::MULTI_FACTOR_AUTH_OPTION_LIST_VISIT)
    end

    def create
      @two_factor_options_form = TwoFactorLoginOptionsForm.new(current_user)
      result = @two_factor_options_form.submit(two_factor_options_form_params)
      analytics.track_event(Analytics::MULTI_FACTOR_AUTH_OPTION_LIST, result.to_h)

      if result.success?
        process_valid_form
      else
        @presenter = two_factor_options_presenter
        render :index
      end
    end

    private

    def two_factor_options_presenter
      TwoFactorLoginOptionsPresenter.new(current_user, view_context, current_sp, session)
    end

    def process_valid_form
      url = mfa_redirect_url
      redirect_to url if url.present?
    end

    def mfa_redirect_url
      selection = @two_factor_options_form.selection
      options = EXTRA_URL_OPTIONS[selection] || {}

      configuration_id = @two_factor_options_form.configuration_id
      user_session[:phone_id] = configuration_id if configuration_id.present?
      options[:id] = user_session[:phone_id]

      build_url(selection, options)
    end

    def build_url(selection, options)
      method = FACTOR_TO_URL_METHOD[selection]
      public_send(method, options) if method.present?
    end

    def two_factor_options_form_params
      params.require(:two_factor_options_form).permit(:selection)
    end
  end
end
