require 'test_helper'

class RemoteRealexTest < Test::Unit::TestCase

  def setup
    @gateway = RealexGateway.new(fixtures(:realex))
    @gateway_with_account = RealexGateway.new(fixtures(:realex_with_account))
    @gateway_with_invalid_account = RealexGateway.new(fixtures(:realex_with_invalid_account))

    # Replace the card numbers with the test account numbers from Realex
    @visa            = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_visa))
    @visa_declined   = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_visa_declined))
    @visa_referral_b = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_visa_referral_b))
    @visa_referral_a = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_visa_referral_a))
    @visa_coms_error = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_visa_coms_error))

    @mastercard            = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_mastercard))
    @mastercard_declined   = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_mastercard_declined))
    @mastercard_referral_b = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_mastercard_referral_b))
    @mastercard_referral_a = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_mastercard_referral_a))
    @mastercard_coms_error = ActiveMerchant::Billing::CreditCard.new(fixtures(:realex_mastercard_coms_error))

    @mock_payer = { first_name: "Tony", last_name: "Gangsta-Riley" }

    @amount = 10000
  end

  if false
  def test_realex_add_payer
    payer_ref = generate_unique_id 
    response = @gateway.create_payer(@mock_payer, order_id: generate_unique_id, payer_ref: payer_ref)
    assert_match 'Successful', response.params['message']
  end

  def test_realex_add_card
    payer_ref = generate_unique_id 
    order_id = generate_unique_id
    payer_response = @gateway.create_payer(@mock_payer, order_id: order_id, payer_ref: payer_ref)

    card_ref = generate_unique_id
    response = @gateway.store(@visa, order_id: generate_unique_id, payer_ref: payer_ref, card_ref: card_ref)
    assert_match 'Successful', response.params['message']
  end

  def test_purchase_with_new_payer
    payer_ref = generate_unique_id 
    card_ref = generate_unique_id
    order_id = generate_unique_id

    @gateway_with_account.create_payer(@mock_payer, order_id: order_id, payer_ref: payer_ref)
    @gateway_with_account.store(@visa, order_id: generate_unique_id, payer_ref: payer_ref, card_ref: card_ref)
    response = @gateway_with_account.purchase_from_stored(12, payer_ref, card_ref, order_id: generate_unique_id)
    assert_match /Authorised|Successful/, response.params['message']
  end

  def test_realex_refund
    # authorize then make refund
    [ @visa, @mastercard ].each do |card|

      response = @gateway.credit(@amount, card, order_id: generate_unique_id)
      puts response.inspect + ' !!!!!!!'

      assert_not_nil response
      assert_success response
    end
  end

  def test_realex_purchase
    [ @visa, @mastercard ].each do |card|

      response = @gateway.purchase(@amount, card, 
                                   :order_id => generate_unique_id,
                                   :description => 'Test Realex Purchase',
                                   :billing_address => {
        :zip => '90210',
        :country => 'US'
      }
                                  )
                                  assert_not_nil response
                                  assert response.test?
                                  assert response.authorization.length > 0
                                  assert_match /Authorised|Successful/, response.params['message']
                                  assert_equal RealexGateway::SUCCESS, response.message
    end      
  end

  def test_realex_purchase_with_invalid_login
    gateway = RealexGateway.new(
      :login => 'invalid',
      :password => 'invalid'
    )
    response = gateway.purchase(@amount, @visa, 
                                :order_id => generate_unique_id,
                                :description => 'Invalid login test'
                               )

                               assert_not_nil response
                               assert_failure response

                               assert_equal '504', response.params['result']
                               assert_equal "There is no such merchant id. Please contact realex payments if you continue to experience this problem.", response.message
  end

  def test_realex_purchase_with_invalid_account
    response = @gateway_with_invalid_account.purchase(@amount, @visa, 
                                                      order_id: generate_unique_id,
                                                      description: 'Test Realex purchase with invalid acocunt'
                                                     )

                                                     assert_not_nil response
                                                     assert_failure response

                                                     assert_equal '506', response.params['result']
                                                     assert_equal "There is no such merchant account. Please contact realex payments if you continue to experience this problem.", response.params['message']
  end

  def test_realex_purchase_declined

    [ @visa_declined, @mastercard_declined ].each do |card|

      response = @gateway.purchase(@amount, card,
                                   :order_id => generate_unique_id,
                                   :description => 'Test Realex purchase declined'
                                  )
                                  assert_not_nil response
                                  assert_failure response

                                  # assert_equal '101', response.params['result']
                                  assert_equal response.params['message'], response.message
    end            

  end

  def test_realex_purchase_referral_b
    [ @visa_referral_b, @mastercard_referral_b ].each do |card|

      response = @gateway.purchase(@amount, card,
                                   :order_id => generate_unique_id,
                                   :description => 'Test Realex Referral B'
                                  )
                                  assert_not_nil response
                                  assert_failure response
                                  assert_equal '102', response.params['result']
                                  assert_equal RealexGateway::DECLINED, response.message
    end
  end

  def test_realex_purchase_referral_a
    [ @visa_referral_a, @mastercard_referral_a ].each do |card|

      response = @gateway.purchase(@amount, card,
                                   :order_id => generate_unique_id,
                                   :description => 'Test Realex Referral A'
                                  )
                                  assert_not_nil response
                                  assert_failure response
                                  # assert_equal '509', response.params['result']
                                  assert_equal RealexGateway::DECLINED, response.message
    end      

  end

  def test_realex_purchase_coms_error

    [ @visa_coms_error, @mastercard_coms_error ].each do |card|

      response = @gateway.purchase(@amount, card,
                                   :order_id => generate_unique_id,
                                   :description => 'Test Realex coms error'
                                  )

                                  assert_not_nil response
                                  assert_failure response

                                  # assert_equal '509', response.params['result']
                                  assert_equal RealexGateway::BANK_ERROR, response.message
    end      

  end

  def test_realex_ccn_error
    @visa.number = '5'

    response = @gateway.purchase(@amount, @visa, 
                                 :order_id => generate_unique_id,
                                 :description => 'Test Realex ccn error'
                                )
                                assert_not_nil response
                                assert_failure response

                                assert_equal '508', response.params['result']
                                assert_equal "Invalid data in CC number field.", response.params['message']
  end

  def test_realex_expiry_month_error
    @visa.month = 13

    response = @gateway.purchase(@amount, @visa, 
                                 :order_id => generate_unique_id,
                                 :description => 'Test Realex expiry month error'
                                )
                                assert_not_nil response
                                assert_failure response

                                assert_equal '509', response.params['result']
                                assert_equal RealexGateway::EXPIRY_DATE_ERROR, response.message
  end

  def test_realex_expiry_year_error
    @visa.year = 2005

    response = @gateway.purchase(@amount, @visa,
                                 :order_id => generate_unique_id,
                                 :description => 'Test Realex expiry year error'
                                )
                                assert_not_nil response
                                assert_failure response

                                assert_equal '509', response.params['result']
                                assert_equal RealexGateway::EXPIRY_DATE_ERROR, response.message
  end

  def test_invalid_credit_card_name
    @visa.first_name = ""
    @visa.last_name = ""

    response = @gateway.purchase(@amount, @visa, 
                                 :order_id => generate_unique_id,
                                 :description => 'test_chname_error'
                                )
                                assert_not_nil response
                                assert_failure response

                                assert_equal '502', response.params['result']
                                assert_equal RealexGateway::MANDATORY_FIELDS_ERROR, response.message
  end

  def test_cvn
    @visa_cvn = @visa.clone
    @visa_cvn.verification_value = "111"
    response = @gateway.purchase(@amount, @visa_cvn, 
                                 :order_id => generate_unique_id,
                                 :description => 'test_cvn'
                                )
                                assert_not_nil response
                                assert_success response
                                assert response.authorization.length > 0
  end

  def test_customer_number
    response = @gateway.purchase(@amount, @visa, 
                                 :order_id => generate_unique_id,
                                 :description => 'test_cust_num',
                                 :customer => 'my customer id'
                                )
                                assert_not_nil response
                                assert_success response
                                assert response.authorization.length > 0
  end

  def test_realex_authorize
    response = @gateway.authorize(@amount, @visa, 
                                  :order_id => generate_unique_id,
                                  :description => 'Test Realex Purchase',
                                  :billing_address => {
      :zip => '90210',
      :country => 'US'
    }
                                 )

                                 assert_not_nil response
                                 assert_success response
                                 assert response.test?
                                 assert response.authorization.length > 0
                                 assert_equal 'Successful', response.message
  end

  def test_realex_authorize_then_capture
    order_id = generate_unique_id

    auth_response = @gateway.authorize(@amount, @visa, 
                                       :order_id => order_id,
                                       :description => 'Test Realex Purchase',
                                       :billing_address => {
      :zip => '90210',
      :country => 'US'
    }
                                      )

                                      capture_response = @gateway.capture(@amount, auth_response.authorization)

                                      assert_not_nil capture_response
                                      assert_success capture_response
                                      assert capture_response.test?
                                      assert capture_response.authorization.length > 0
                                      assert_equal 'Successful', capture_response.message
                                      assert_match /Settled Successfully/, capture_response.params['message']
  end

  def test_realex_purchase_then_void
    order_id = generate_unique_id

    purchase_response = @gateway.purchase(@amount, @visa, 
      :order_id => order_id,
      :description => 'Test Realex Purchase',
      :billing_address => {
      :zip => '90210',
      :country => 'US'
      }
      )

      void_response = @gateway.void(purchase_response.authorization)

      assert_not_nil void_response
      assert_success void_response
      assert void_response.test?
      assert void_response.authorization.length > 0
      assert_equal 'Successful', void_response.message
      assert_match /Voided Successfully/, void_response.params['message']
  end


  def test_realex_purchase_then_credit
    order_id = generate_unique_id

    @gateway_with_refund_password = RealexGateway.new(fixtures(:realex).merge(:rebate_secret => 'refund'))

    purchase_response = @gateway_with_refund_password.purchase(@amount, @visa, 
    :order_id => order_id,
    :description => 'Test Realex Purchase',
    :billing_address => {
    :zip => '90210',
    :country => 'US'
    }
    )

    rebate_response = @gateway_with_refund_password.refund(@amount, purchase_response.authorization)
    puts rebate_response.inspect

    assert_not_nil rebate_response
    assert_success rebate_response
    assert rebate_response.test?
    assert rebate_response.authorization.length > 0
    assert_equal 'Successful', rebate_response.message
    end

  end

  def test_realex_credit
    order_id = generate_unique_id

    @gateway = RealexGateway.new(fixtures(:realex).merge(rebate_secret: 'credit'))
    response = @gateway.credit(@amount, @visa,
                               order_id: order_id)
    puts response.inspect + ' <<<<RESPONSE'
  end
end
