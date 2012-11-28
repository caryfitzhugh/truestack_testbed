class FuzzController < ApplicationController
  def index
    render :text => "OK"
  end

  def exception
    throw "ACK!"
  end
end
