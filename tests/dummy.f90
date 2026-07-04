program dummy
    implicit none
    integer, allocatable :: realloc_probe(:)
    integer :: source_four(4)

    source_four = 7

    ! F2018 realloc-on-assignment must behave identically in every config.
    ! (Release 1.4.x carried -fno-realloc-lhs and silently kept the old size.)
    allocate(realloc_probe(3))
    realloc_probe = source_four
    if (size(realloc_probe) /= 4) then
        print *, "FAIL: realloc-on-assignment kept size ", size(realloc_probe)
        stop 1
    end if

    ! gfortran does not auto-deallocate main-program allocatables at exit, so
    ! free it explicitly to keep the probe clean under the sanitizers preset.
    deallocate(realloc_probe)

    print *, "GCCCompilerOptions: Fortran compile test passed."
end program dummy
