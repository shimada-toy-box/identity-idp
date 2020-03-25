require 'rails_helper'

describe 'Account connected applications' do
  let(:user) { create(:user, :signed_up, created_at: Time.zone.now - 100.days) }
  let(:identity_with_link) do
    create(
      :identity,
      :active,
      user: user,
      created_at: Time.zone.now - 80.days,
      service_provider: 'http://localhost:3000',
    )
  end
  let(:identity_without_link) do
    create(
      :identity,
      :active,
      user: user,
      created_at: Time.zone.now - 50.days,
      service_provider: 'https://rp2.serviceprovider.com/auth/saml/metadata',
    )
  end
  let(:identity_with_link_timestamp) { identity_with_link.decorate.created_at_in_words }
  let(:identity_without_link_timestamp) { identity_without_link.decorate.created_at_in_words }

  before do
    sign_in_and_2fa_user(user)
    build_account_connected_apps
    visit account_path
  end

  scenario 'viewing account connected applications' do
    expect(page).to have_content(t('headings.account.connected_apps'))

    expect(page).to have_content( \
      t('event_types.authenticated_at', service_provider: identity_without_link.display_name),
    )
    expect(page).to_not have_link(identity_without_link.display_name)

    expect(page).to have_content( \
      t(
        'event_types.authenticated_at_html',
        service_provider_link: identity_with_link.display_name,
      ),
    )
    expect(page).to have_link( \
      identity_with_link.display_name, href: 'http://localhost:3000'
    )

    expect(identity_without_link_timestamp).to appear_before(identity_with_link_timestamp)
  end

  scenario 'revoking consent from an SP' do
    identity_to_revoke = identity_with_link

    expect(page).to have_content(
      t('event_types.authenticated_at', service_provider: identity_to_revoke.display_name),
    )

    within(find('.profile-info-box', text: t('headings.account.connected_apps'))) do
      within(find('.mxn1', text: identity_to_revoke.sp.friendly_name)) do
        click_link(t('account.revoke_consent.link_title'))
      end
    end

    expect(page).to have_content(identity_to_revoke.sp.friendly_name)
    click_on t('forms.buttons.continue')

    # Accounts page should no longer list this app in the applications section
    within(find('.profile-info-box', text: t('headings.account.connected_apps'))) do
      expect(has_selector?('.mxn1', text: identity_to_revoke.sp.friendly_name)).to eq(false)
    end
  end

  def build_account_connected_apps
    identity_with_link
    identity_without_link
  end
end
