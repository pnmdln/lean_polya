import .rat


meta instance : has_to_format ℤ := ⟨λ z, int.rec_on z (λ k, ↑k) (λ k, "-"++↑(k+1)++"")⟩

meta def num_denum_format : rat.num_denum → format
| (num, ⟨denum, _⟩) := 
if num = 0 then "0"
else if denum = 1 then to_fmt num
else to_fmt num ++ "/" ++ to_fmt denum

meta def num_denum_format_wf : Π a b : rat.num_denum, rat.rel a b → num_denum_format a = num_denum_format b := sorry


meta instance : has_to_format ℚ :=
⟨quot.lift num_denum_format num_denum_format_wf⟩