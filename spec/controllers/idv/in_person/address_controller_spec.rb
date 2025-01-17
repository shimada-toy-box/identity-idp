require 'rails_helper'

RSpec.describe Idv::InPerson::AddressController do
  include InPersonHelper
  let(:in_person_residential_address_controller_enabled) { true }
  let(:pii_from_user) { Idp::Constants::MOCK_IPP_APPLICANT_SAME_ADDRESS_AS_ID_FALSE.dup }
  let(:user) { build(:user) }
  let(:flow_session) do
    { pii_from_user: pii_from_user }
  end
  let(:flow_path) { 'standard' }

  before(:each) do
    allow(IdentityConfig.store).to receive(:in_person_residential_address_controller_enabled).
      and_return(true)
    allow(subject).to receive(:current_user).
      and_return(user)
    allow(subject).to receive(:pii_from_user).and_return(pii_from_user)
    allow(subject).to receive(:flow_session).and_return(flow_session)
    allow(subject).to receive(:flow_path).and_return(flow_path)
    stub_sign_in(user)
    stub_analytics
    allow(@analytics).to receive(:track_event)
  end

  describe 'before_actions' do
    context '#render_404_if_in_person_residential_address_controller_enabled not set' do
      context 'flag not set' do
        before do
          allow(IdentityConfig.store).to receive(:in_person_residential_address_controller_enabled).
            and_return(nil)
        end
        it 'renders a 404' do
          get :show

          expect(response).to be_not_found
        end
      end

      context 'flag not enabled' do
        before do
          allow(IdentityConfig.store).to receive(:in_person_residential_address_controller_enabled).
            and_return(false)
        end
        it 'renders a 404' do
          get :show

          expect(response).to be_not_found
        end
      end
    end

    context '#confirm_in_person_state_id_step_complete' do
      it 'redirects to state id page if not complete' do
        flow_session[:pii_from_user].delete(:identity_doc_address1)
        get :show

        expect(response).to redirect_to idv_in_person_step_url(step: :state_id)
      end
    end

    context '#confirm_in_person_address_step_needed' do
      context 'step is not needed' do
        it 'redirects to ssn page when same address as id is true' do
          flow_session[:pii_from_user][:same_address_as_id] = 'true'
          get :show
          expect(response).to redirect_to idv_in_person_ssn_url
        end

        it 'redirects to ssn page when address1 present' do
          flow_session[:pii_from_user][:address1] = '123 Main St'
          get :show
          expect(response).to redirect_to idv_in_person_ssn_url
        end
      end
    end
  end

  describe '#show' do
    let(:analytics_name) { 'IdV: in person proofing address visited' }
    let(:analytics_args) do
      {
        analytics_id: 'In Person Proofing',
        flow_path: flow_path,
        irs_reproofing: false,
        step: 'address',
        step_count: nil,
      }
    end

    context 'with address controller flag enabled' do
      it 'renders the show template' do
        get :show

        expect(response).to render_template :show
      end

      it 'logs idv_in_person_proofing_address_visited' do
        get :show

        expect(@analytics).to have_received(
          :track_event,
        ).with(analytics_name, analytics_args)
      end

      it 'has correct extra_view_variables' do
        expect(subject.extra_view_variables).to include(
          form: Idv::InPerson::AddressForm,
          updating_address: false,
        )

        expect(subject.extra_view_variables[:pii]).to_not have_key(
          :address1,
        )
      end
    end
  end
end
