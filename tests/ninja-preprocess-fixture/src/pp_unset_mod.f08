module pp_unset_mod
    !! Reference values from https://physics.nist.gov/constants
    implicit none
    ! gcc-opts passes -fmodule-private, so the export must be explicit.
    public :: pp_unset_value
contains
    integer function pp_unset_value() result(r)
#ifdef FIXTURE_DEFINE
        r = 42
#else
        r = 7
#endif
    end function pp_unset_value
end module pp_unset_mod
