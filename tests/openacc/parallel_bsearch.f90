!! OpenMP 4.1 Example 29.2f
!! The following is the equivalent parallel search example in Fortran.
module parallel_bsearch
    use openacc
 type binary_tree
 integer :: value
 type(binary_tree), pointer :: right
 type(binary_tree), pointer :: left
 end type
!
contains
 recursive subroutine search_tree(tree, value, level, found)
 type(binary_tree), intent(in), pointer :: tree
 integer, intent(in) :: value, level
 type(binary_tree), pointer :: found
 type(binary_tree), pointer :: found_left => NULL(), found_right => NULL()
#if _OPENACC >  201306
 if (.not. associated(found)) then
 allocate(found)
 endif
!
 if (associated(tree)) then
 if (tree%value .eq. value) then
 found = tree
 else
!$omp task shared(found) if(level<10)
 call search_tree(tree%left, value, level+1, found_left)
 if (associated(found_left)) then
!$omp atomic write
 found = found_left
!
!$omp cancel taskgroup
 endif
!$omp end task
!
!$omp task shared(found) if(level<10)
 call search_tree(tree%right, value, level+1, found_right)
 if (associated(found_right)) then
!$omp atomic write
 found = found_right
!
!$omp cancel taskgroup
 endif
!$omp end task
!
!$omp taskwait
 endif
endif


#endif
 end subroutine
!

 subroutine search_tree_parallel(tree, value, found)
 type(binary_tree), intent(in), pointer :: tree
 integer, intent(in) :: value
 type(binary_tree), pointer :: found
 !
#if _OPENACC >  201306
 return
#endif
 if (associated(found)) then
 allocate(found)
 endif
!$omp parallel shared(found, tree, value)
!$omp master
!$omp taskgroup
 call search_tree(tree, value, 0, found)
!$omp end taskgroup
!$omp end master
!$omp end parallel
 end subroutine
!

end module parallel_bsearch
