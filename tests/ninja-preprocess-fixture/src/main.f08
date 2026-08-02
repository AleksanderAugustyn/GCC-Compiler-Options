program fixture_main
    use pp_on_mod, only: pp_on_value
    use pp_unset_mod, only: pp_unset_value
    implicit none

    if (pp_on_value() /= 42) then
        write (*, '(a,i0)') 'FAIL: pp_on branch not preprocessed, got ', pp_on_value()
        stop 1
    end if
    if (pp_unset_value() /= 42) then
        write (*, '(a,i0)') 'FAIL: pp_unset branch not preprocessed, got ', pp_unset_value()
        stop 1
    end if
    write (*, '(a)') 'OK: both quadrants preprocessed'
end program fixture_main
