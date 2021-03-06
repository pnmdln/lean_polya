import .control .proof_trace

open polya tactic expr

variables u v w x y z : ℚ

private lemma rat_one_gt_zero : (1 : ℚ) > 0 := zero_lt_one
local infix `^` := rat.pow
meta def polya_on_hyps' (hys : list name) (rct : bool := tt) : tactic unit :=
do exps ← hys.mmap get_local,
   bb ← add_proof_to_blackboard blackboard.mk_empty `(rat_one_gt_zero),
   bb ← add_proofs_to_blackboard bb exps,
   let pb := polya_bundle.default.set_blackboard bb,
   let (n, pb) := pb.cycle 0,
   trace ("number of cycles:", n),
   trace ("contr found", pb.contr_found),
   if bnot pb.contr_found then /-bb.trace >>-/ fail "polya failed, no contradiction found" else do
   pb.bb.contr.sketch >>= proof_sketch.trace,
   if rct then pb.bb.contr.reconstruct >>= apply
   else skip

example  (h1 : x > 0) (h2 : x < 1*1) (h3 : rat.pow (1*1 + (-1)*x) (-1) ≤ 1*(rat.pow (1*1 + (-1)*rat.pow x 2) (-1))) : false :=
by 
polya_on_hyps' [`h1, `h2, `h3]


example (h1 : u > 0) (h2 : u < 1*v) (h3 : z > 0) (h4 : 1*z + 1*1 < 1*w) (h5 : rat.pow (1*u + 1*v + 1*z) 3 ≥ 1* rat.pow (1*u + 1*v + 1*w + 1*1) 5) : false :=
by  polya_on_hyps' [`h1, `h2, `h3, `h4, `h5]
