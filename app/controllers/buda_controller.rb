class BudaController < ApplicationController
  def index

    start_timestamp = Time.parse("1 de marzo de 2024 12:00:00 GMT-03:00").to_i * 1000
    end_timestamp = Time.parse("1 de marzo de 2024 13:00:00 GMT-03:00").to_i * 1000

    trades_info = Buda.trades_info(start_timestamp, end_timestamp)

    @buda_result = trades_info
    render json: @buda_result
  end
end