module pp_on_mod
    !! Reference values from https://physics.nist.gov/constants
    implicit none
    ! gcc-opts passes -fmodule-private, so the export must be explicit.
    public :: pp_on_value
contains
    integer function pp_on_value() result(r)
#ifdef FIXTURE_DEFINE
        r = 42
#else
        r = 7
#endif
    end function pp_on_value
end module pp_on_mod
