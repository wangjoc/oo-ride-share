require_relative 'test_helper'

TEST_DATA_DIRECTORY = 'test/test_data'

describe "TripDispatcher class" do
  def build_test_dispatcher
    return RideShare::TripDispatcher.new(
      directory: TEST_DATA_DIRECTORY
    )
  end

  describe "Initializer" do
    it "is an instance of TripDispatcher" do
      dispatcher = build_test_dispatcher
      expect(dispatcher).must_be_kind_of RideShare::TripDispatcher
    end

    it "establishes the base data structures when instantiated" do
      dispatcher = build_test_dispatcher
      [:trips, :passengers].each do |prop|
        expect(dispatcher).must_respond_to prop
      end

      expect(dispatcher.trips).must_be_kind_of Array
      expect(dispatcher.passengers).must_be_kind_of Array
      # expect(dispatcher.drivers).must_be_kind_of Array
    end

    it "loads the development data by default" do
      # Count lines in the file, subtract 1 for headers
      trip_count = %x{wc -l 'support/trips.csv'}.split(' ').first.to_i - 1

      dispatcher = RideShare::TripDispatcher.new
      expect(dispatcher.trips.length).must_equal trip_count
    end
  end

  describe "passengers" do
    describe "find_passenger method" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect{ @dispatcher.find_passenger(0) }.must_raise ArgumentError
      end

      it "finds a passenger instance" do
        passenger = @dispatcher.find_passenger(2)
        expect(passenger).must_be_kind_of RideShare::Passenger
      end
    end

    describe "Passenger & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads passenger information into passengers array" do
        first_passenger = @dispatcher.passengers.first
        last_passenger = @dispatcher.passengers.last

        expect(first_passenger.name).must_equal "Passenger 1"
        expect(first_passenger.id).must_equal 1
        expect(last_passenger.name).must_equal "Passenger 8"
        expect(last_passenger.id).must_equal 8
      end

      it "connects trips and passengers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.passenger).wont_be_nil
          expect(trip.passenger.id).must_equal trip.passenger_id
          expect(trip.passenger.trips).must_include trip
        end
      end
    end
  end

  # TODO: un-skip for Wave 2
  describe "drivers" do
    describe "find_driver method" do
      
      before do
        @dispatcher = build_test_dispatcher
      end

      it "throws an argument error for a bad ID" do
        expect { @dispatcher.find_driver(0) }.must_raise ArgumentError
      end

      it "finds a driver instance" do
        
        driver = @dispatcher.find_driver(2)
        expect(driver).must_be_kind_of RideShare::Driver
      end
    end

    describe "Driver & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end

      it "accurately loads driver information into drivers array" do
        first_driver = @dispatcher.drivers.first
        last_driver = @dispatcher.drivers.last

        expect(first_driver.name).must_equal "Driver 1 (unavailable)"
        expect(first_driver.id).must_equal 1
        expect(first_driver.status).must_equal :UNAVAILABLE
        expect(last_driver.name).must_equal "Driver 3 (no trips)"
        expect(last_driver.id).must_equal 3
        expect(last_driver.status).must_equal :AVAILABLE
      end

      it "connects trips and drivers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.driver).wont_be_nil
          expect(trip.driver.id).must_equal trip.driver_id
          expect(trip.driver.trips).must_include trip
        end
      end
    end
  end

  describe 'requests and creates new trip' do
    it 'adds trip to passengers' do
      @dispatcher = build_test_dispatcher
      passenger_num_trips = @dispatcher.find_passenger(5).trips.length

      request_trip_result = @dispatcher.request_trip(5)
    
      expect(@dispatcher.find_passenger(5).trips.length).must_equal (passenger_num_trips + 1)
    end
    
    it 'adds trip to driver' do
      @dispatcher = build_test_dispatcher
      chosen_driver = @dispatcher.first_available_driver
      driver_num_trips = @dispatcher.drivers[chosen_driver].trips.length
  
      request_trip_result = @dispatcher.request_trip(5)
    
      expect(@dispatcher.drivers[chosen_driver].id).must_equal 3
      expect(@dispatcher.drivers[chosen_driver].status).must_equal :UNAVAILABLE
      expect(@dispatcher.drivers[chosen_driver].trips.length).must_equal (driver_num_trips + 1)
    end

    it 'confirms trip was added to trips' do
      @dispatcher = build_test_dispatcher
      old_num_trips = @dispatcher.trips.length

      request_trip_result = @dispatcher.request_trip(5)
    
      expect(request_trip_result).must_be_kind_of RideShare::Trip
      expect(@dispatcher.trips.length).must_equal (old_num_trips + 1)
    end
  end

  describe 'check first available driver' do
    it 'will return the first available driver' do
      @dispatcher = build_test_dispatcher

      request_trip_result = @dispatcher.request_trip(5)
      request_trip_result = @dispatcher.request_trip(6)

      expect { @dispatcher.request_trip(7) }.must_raise ArgumentError
    end
  end

  describe 'find driver and passenger total for in-progress' do
    before do
      @dispatcher = build_test_dispatcher
      request_trip_result = @dispatcher.request_trip(5)
      @chosen_driver = @dispatcher.first_available_driver
      request_trip_result = @dispatcher.request_trip(1)
    end

    it 'will return passenger expend, excluding trip in-progress' do  
      @dispatcher.find_passenger(5).net_expenditures.must_equal 0
      @dispatcher.find_passenger(1).net_expenditures.must_equal 10
    end

    it 'will return passenger time spent, excluding trip in-progress' do
      @dispatcher.find_passenger(5).total_time_spent.must_equal 0
      @dispatcher.find_passenger(1).total_time_spent.must_equal 1940
    end

    it 'will return driver revenue, excluding trip in-progress' do
      @dispatcher.drivers[@chosen_driver].total_revenue.must_equal 40.04
    end

    it 'will return driver average, excluding trip in-progress' do
      @dispatcher.drivers[@chosen_driver].average_rating.must_equal 2
    end
  end

end
