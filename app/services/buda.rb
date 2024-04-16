# frozen_string_literal: true
class Buda

  BASE_URL = 'https://www.buda.com/api/v2'

  def self.trades_info(start_timestamp, final_timestamp)
    all_trades = trades(start_timestamp, final_timestamp,25)
    black_buda_amount = calculate_black_buda_amount(all_trades).round(2)
    last_year_difference = calculate_past_year_difference(all_trades, start_timestamp, final_timestamp).round(2)
    lost_commission_difference = calculate_commission_difference(all_trades, 0.008).round(2)

    {
      start_timestamp: start_timestamp,
      final_timestamp: final_timestamp,
      "black_buda_total_transactions (CLP)": black_buda_amount,
      "last_year_black_buda_difference (BTC) %": last_year_difference,
      "lost_commission_difference (CLP)": lost_commission_difference
    }
  end

  private

  def self.trades(start_timestamp, final_timestamp, limit)
    all_trades = []
    url = "#{BASE_URL}/markets/BTC-CLP/trades"
    last_current_timestamp = final_timestamp
    loop do
      query_params = { timestamp: last_current_timestamp, limit: limit}
      response = HTTParty.get(url, query: query_params)
      body = response.parsed_response
      entries = body["trades"]["entries"]
      all_trades <<  entries if entries.present?
      if  last_current_timestamp < start_timestamp
        break
      end
      last_current_timestamp = body["trades"]["last_timestamp"].to_i + 1
    end
    clean(all_trades, start_timestamp, final_timestamp)
  end

  def self.clean(all_trades, start_timestamp, final_timestamp)
    all_trades = all_trades.flatten!(1)
    all_trades.select do |trade|
      timestamp = trade[0].to_i
      timestamp >= start_timestamp && timestamp <= final_timestamp
    end
  end

  def self.calculate_black_buda_amount(trades)
    total_transactions = 0
    trades.each_with_index do |trade|
      total_transactions+= trade[1].to_f * trade[2].to_f
    end
    total_transactions
  end

  def self.calculate_past_year_difference(all_trades, start_timestamp, final_timestamp)
    this_year_trades = all_trades
    this_year_volume_total = 0
    this_year_trades.each_with_index do |trade|
      this_year_volume_total += trade[1].to_f
    end

    past_year_start_timestamp = Time.at(start_timestamp/1000).prev_year.to_i
    past_year_final_timestamp = Time.at(final_timestamp/1000).prev_year.to_i

    past_year_trades = trades(past_year_start_timestamp*1000, past_year_final_timestamp*1000 ,25)

    past_year_volume_total = 0
    past_year_trades.each_with_index do |trade|
      past_year_volume_total += trade[1].to_f
    end

    difference = ((this_year_volume_total - past_year_volume_total) / past_year_volume_total) * 100
    difference.round(2)
  end

  def self.calculate_commission_difference(all_trades, commission)
    accumulate_commissions  = 0
    all_trades.each_with_index do |trade|
      accumulate_commissions += ( trade[1].to_f * trade[2].to_f ) * commission
    end
    accumulate_commissions
  end
end