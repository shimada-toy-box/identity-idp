class OtpRequestsTracker < ApplicationRecord
  def self.find_or_create_with_phone_and_confirmed(phone, phone_confirmed)
    tries = 1
    phone_fingerprint = Pii::Fingerprinter.fingerprint(phone.strip)

    where(phone_fingerprint: phone_fingerprint, phone_confirmed: phone_confirmed).
      first_or_create(otp_send_count: 0, otp_last_sent_at: Time.zone.now)
  rescue ActiveRecord::RecordNotUnique
    retry unless (tries -= 1).zero?
    raise
  end

  def self.atomic_increment!(otp_request_tracker)
    id = otp_request_tracker.id
    now = Time.zone.now
    # The following sql offers superior db performance with one write and no locking overhead
    query = sanitize_sql_array(
      ['UPDATE otp_requests_trackers ' \
       'SET otp_send_count = otp_send_count + 1,' \
       'otp_last_sent_at = ?, updated_at = ? ' \
       'WHERE id = ? ' \
       'RETURNING otp_send_count, otp_last_sent_at, updated_at',
       now, now, id],
    )
    result = OtpRequestsTracker.connection.execute(query).first
    otp_request_tracker.otp_send_count = result['otp_send_count']
    otp_request_tracker.otp_last_sent_at = result['otp_last_sent_at']
    otp_request_tracker.updated_at = result['updated_at']

    otp_request_tracker
  end
end
