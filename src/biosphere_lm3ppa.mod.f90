module md_biosphere_lm3ppa

  use datatypes
  use md_vegetation_lm3ppa
  use md_soil_lm3ppa
  use md_params_core_lm3ppa

  implicit none

  private
  public biosphere_annual

   type(vegn_tile_type),  pointer :: vegn
   type(soil_tile_type),  pointer :: soil
   type(cohort_type),     pointer :: cx, cc

contains

  function biosphere_annual() result( out_biosphere )
    !////////////////////////////////////////////////////////////////
    ! function BIOSPHERE_annual calculates net ecosystem exchange (nee)
    ! in response to environmental boundary conditions (atmospheric 
    ! CO2, temperature, Nitrogen deposition. This SR "replaces" 
    ! LPJ, also formulated as subroutine.
    ! Copyright (C) 2015, see LICENSE, Benjamin David Stocker
    ! contact: b.stocker@imperial.ac.uk
    !----------------------------------------------------------------
    use md_interface_lm3ppa, only: myinterface, outtype_biosphere
    use md_params_core_lm3ppa, only: ntstepsyear
  
    ! return variable
    type(outtype_biosphere) :: out_biosphere

    ! ! local variables
    integer :: dm, moy, doy
    ! logical, save           :: init_daily = .true.   ! is true only on the first day of the simulation 
    logical, parameter :: verbose = .false.       ! change by hand for debugging etc.

    !----------------------------------------------------------------
    ! Biome-E stuff
    !----------------------------------------------------------------
    integer, parameter :: rand_seed = 86456
    integer, parameter :: totalyears = 10
    integer, parameter :: nCohorts = 1
    real    :: tsoil, soil_theta
    integer :: year0
    integer :: i, j, idoy
    integer :: idata
    integer, save :: simu_steps !, datalines
    integer, save :: iyears
    ! character(len=50) :: namelistfile = '~/sofun/params/parameters_Allocation.nml' !'parameters_WC_biodiversity.nml' ! 'parameters_CN.nml'
    
    !----------------------------------------------------------------
    ! INITIALISATIONS
    !----------------------------------------------------------------
    if (myinterface%steering%init) then

      allocate(out_biosphere%hourly_tile(ntstepsyear))

      ! Parameter initialization: Initialize PFT parameters
      call initialize_PFT_data()

      ! Initialize vegetation tile and plant cohorts
      allocate(vegn)

      print*,'2: ', vegn%n_cohorts
      call initialize_vegn_tile(vegn,nCohorts)
      
      ! Sort and relayer cohorts

      print*,'3: ', vegn%n_cohorts
      call relayer_cohorts(vegn)

      print*,'4: ', vegn%n_cohorts
      call Zero_diagnostics(vegn)

      year0 = myinterface%climate(1)%year  ! forcingData(1)%year
      iyears = 1
      idoy = 0

    endif 

    simu_steps = 0

    !----------------------------------------------------------------
    ! LOOP THROUGH MONTHS
    !----------------------------------------------------------------
    doy = 0
    monthloop: do moy=1,nmonth

      !----------------------------------------------------------------
      ! LOOP THROUGH DAYS
      !----------------------------------------------------------------
      dayloop: do dm=1,ndaymonth(moy)
        
        doy = doy + 1

        if (verbose) print*,'----------------------'
        if (verbose) print*,'YEAR, Doy ', myinterface%steering%year, doy
        if (verbose) print*,'----------------------'

        idoy = idoy + 1

        !----------------------------------------------------------------
        ! Get daily mean air and soil temperature
        !----------------------------------------------------------------

        ! get daily mean temperature from hourly/half-hourly data
        vegn%Tc_daily = 0.0
        tsoil         = 0.0

        fastloop: do i=1,myinterface%steps_per_day

          ! idata = MOD(simu_steps, myinterface%datalines)+1
          idata = simu_steps + 1
          year0 =  myinterface%climate(idata)%year  ! Current year
          vegn%Tc_daily = vegn%Tc_daily +  myinterface%climate(idata)%Tair

          tsoil         = myinterface%climate(idata)%tsoil
          simu_steps    = simu_steps + 1

          call vegn_CNW_budget_fast(vegn, myinterface%climate(idata))
        
          !print*,'idata, size', idata, size(out_biosphere%hourly_tile)
          call hourly_diagnostics(vegn, myinterface%climate(idata), iyears, idoy, i, out_biosphere%hourly_tile(idata) )

        enddo fastloop ! hourly or half-hourly

        vegn%Tc_daily = vegn%Tc_daily/myinterface%steps_per_day
        tsoil         = tsoil/myinterface%steps_per_day
        soil_theta    = vegn%thetaS

!         !-------------------------------------------------
!         ! Daily calls
!         !-------------------------------------------------
        
!         call daily_diagnostics(vegn, myinterface%climate(idata), iyears, idoy, out_biosphere%daily_cohorts(doy,:), out_biosphere%daily_tile(doy) )
!         !print*,'5: ', vegn%n_cohorts
!         ! Determine start and end of season and maximum leaf (root) mass
!         !print*,'4: ', vegn%n_cohorts
!         call vegn_phenology(vegn, j)

!         ! Produce new biomass from 'carbon_gain' (is zero afterwards)
!         !print*,'4: ', vegn%n_cohorts
!         call vegn_growth_EW(vegn)

!         !----------------------------------------------------------------
!         ! populate function return variable
!         !----------------------------------------------------------------

      end do dayloop

    end do monthloop

!     !----------------------------------------------------------------
!     ! Annual calls
!     !----------------------------------------------------------------
!      idoy = 0

!     print*,'sim. year  ', iyears
!     print*,'real year: ', year0


!     if ( myinterface%params_siml%update_annualLAImax ) call vegn_annualLAImax_update(vegn)

!     call annual_diagnostics(vegn, iyears, out_biosphere%annual_cohorts(:), out_biosphere%annual_tile)

!     !---------------------------------------------
!     ! Reproduction and mortality
!     !---------------------------------------------        
!     ! Kill all individuals in a cohort if NSC falls below critical point
!     call vegn_annual_starvation(vegn)
!      print*,'5: ', vegn%n_cohorts

!     ! Natural mortality (reducing number of individuals 'nindivs')
!     ! (~Eq. 2 in Weng et al., 2015 BG)
!     call vegn_nat_mortality(vegn, real( seconds_per_year ))
!      print*,'6: ', vegn%n_cohorts

!     ! seed C and germination probability (~Eq. 1 in Weng et al., 2015 BG)
!     call vegn_reproduction(vegn)
!      print*,'7: ', vegn%n_cohorts

!     !---------------------------------------------
!     ! Re-organize cohorts
!     !---------------------------------------------
!     call kill_lowdensity_cohorts(vegn)
!     print*,'8: ', vegn%n_cohorts
!     call relayer_cohorts(vegn)
!     print*,'9: ', vegn%n_cohorts
!     call vegn_mergecohorts(vegn)
!     print*,'10: ', vegn%n_cohorts

!     ! !---------------------------------------------
!     ! ! Set annual variables zero
!     ! !---------------------------------------------
!     call Zero_diagnostics(vegn)
!     print*,'11: ', vegn%n_cohorts

!     ! update the years of model run
!     iyears = iyears + 1

!     if (myinterface%steering%finalize) then
!       !----------------------------------------------------------------
!       ! Finazlize run: deallocating memory
!       !----------------------------------------------------------------
!       deallocate(vegn%cohorts)

!     end if

!     if (verbose) print*,'Done with biosphere for this year. Guete Rutsch!'

  end function biosphere_annual

end module md_biosphere_lm3ppa
