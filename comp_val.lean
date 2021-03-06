/-
Copyright (c) 2017 Robert Y. Lewis. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Robert Y. Lewis

The built-in comp_val tactic only applies to ℕ and certain other datatypes.
This extends it to work on arbitrary algebraic structures.
For efficiency reasons, this should be ported to C++ eventually.
-/

#exit

import data.rat
open tactic expr
universe u

variables {α : Type u} {a b : α}
section semirings
variable  [linear_ordered_semiring α]

theorem bit0_ge_bit0 (h : a ≥ b) : bit0 a ≥ bit0 b := add_le_add h h

theorem bit0_gt_bit0 (h : a > b) : bit0 a > bit0 b := 
add_lt_add h h

theorem bit1_gt_bit0 (h : a ≥ b) : bit1 a > bit0 b := 
suffices a + a + 1 > b + b + 0, by rw add_zero at this; apply this,
add_lt_add_of_le_of_lt (bit0_ge_bit0 h) zero_lt_one

theorem bit0_gt_bit1 (h : a ≥ b + 1) : bit0 a > bit1 b := 
begin
unfold bit0 bit1,
apply lt_of_lt_of_le,
rotate 1,
apply add_le_add,
repeat {apply h},
simp,
apply add_lt_add_left,
apply add_lt_add_left,
apply lt_add_of_pos_left,
apply zero_lt_one
end

theorem bit0_gt_bit1' {c : α} (h : a ≥ c) (h2 : b+1=c) : bit0 a > bit1 b :=
begin apply bit0_gt_bit1, rw h2, apply h
end

theorem bit1_gt_bit1  (h : a > b) : bit1 a > bit1 b := 
add_lt_add_right (bit0_gt_bit0 h) _

theorem bit0_gt_zero (h : a > 0) : bit0 a > 0 :=
add_pos h h

theorem bit1_gt_zero (h : a ≥ 0) : bit1 a > 0 :=
add_pos_of_nonneg_of_pos (add_nonneg h h) zero_lt_one

theorem bit0_gt_one (h : a ≥ 1) : bit0 a > 1 :=
begin
unfold bit0,
rw [←zero_add (1 : α)],
apply add_lt_add_of_lt_of_le,
apply lt_of_lt_of_le,
apply zero_lt_one,
repeat {assumption}
end

theorem bit1_gt_one (h : a > 0) : bit1 a > 1 :=
begin
unfold bit1 bit0,
apply lt_add_of_pos_left,
apply add_pos,
repeat {assumption}
end
end semirings

section rings
variable [linear_ordered_ring α]

theorem gt_neg {c : α} (h : a + b = c) (h2 : c > 0) : a > -b := 
have h' : b + a = c, from add_comm a b ▸ h,
calc
  a = -b + c : eq_neg_add_of_add_eq h'
... > -b : lt_add_of_pos_right _ h2

end rings


set_option eqn_compiler.max_steps 20000
meta def mk_gt_prf (mk_ge_prf : expr → expr → tactic expr) : expr → expr → tactic expr 
| (`(bit0 %%t1)) (`(bit0 %%t2)) := 
   do prf ← mk_gt_prf t1 t2,
      to_expr ``(bit0_gt_bit0 %%prf)
| (`(bit1 %%t1)) (`(bit0 %%t2)) := 
   do prf ← mk_ge_prf t1 t2,
      tactic.mk_app `bit1_gt_bit0 [prf]
| (`(bit0 %%t1)) (`(@bit1 %%t %%_ %%_ %%t2)) := 
   do (n, eqp) ← to_expr ``(%%t2 + 1 : %%t) >>= norm_num, prf ← mk_ge_prf t1 n,
      tactic.mk_app `bit0_gt_bit1' [prf, eqp]
| (`(bit1 %%t1)) (`(bit1 %%t2)) := 
   do prf ← mk_gt_prf t1 t2,
      tactic.mk_app `bit1_gt_bit1 [prf]
| (`(bit0 %%t1)) (`(@has_zero.zero %%t %%_)) :=
   do prf ← to_expr ``(0 : %%t) >>= mk_gt_prf t1,
      tactic.mk_app `bit0_gt_zero [prf]
| (`(bit0 %%t1)) (`(@has_one.one %%t %%_)) :=
   do prf ← to_expr ``(1 : %%t) >>= mk_ge_prf t1,
      to_expr ``(bit0_gt_one %%prf) --tactic.mk_mapp `bit0_gt_one [none, none, some t1, some prf]
| (`(bit1 %%t1)) (`(@has_zero.zero %%t %%_)) :=
   do prf ← to_expr ``(0 : %%t) >>= mk_ge_prf t1 ,
      tactic.mk_app `bit1_gt_zero [prf]
| (`(@bit1 %%_ %%_ %%_ %%t1)) (`(@has_one.one %%t %%_)) :=
   do prf ← to_expr ``(0 : %%t) >>= mk_gt_prf t1,
      tactic.mk_app `bit1_gt_one [prf]
| (`(@has_one.one %%tp %%_)) (`(@has_zero.zero %%_ %%_)) := trace "abc" >> to_expr ``(@zero_lt_one %%tp _) 
| (t1) `(@has_neg.neg %%tp %%_ %%t2) :=
  do (n, eqp) ← to_expr ``(%%t1 + %%t2) >>= norm_num, prf ← to_expr ``(0 : %%tp) >>= mk_gt_prf n,
      tactic.mk_app `gt_neg [eqp, prf]
| a b := tactic.fail "mk_gt_prf failed"



meta def mk_ge_prf : expr → expr → tactic expr := λ e1 e2,
(guard (e1 = e2) >> to_expr ``((le_refl _ : %%e1 ≥ %%e2))) <|> do
  gtprf ← mk_gt_prf mk_ge_prf e1 e2,
  mk_app `le_of_lt [gtprf]


lemma rat_gt {a b c d : ℚ} (h : a*d > c*b) (hb : b > 0) (hd : d > 0) : a / b > c / d :=
begin
apply lt_div_of_mul_lt,
assumption,
rw div_mul_eq_mul_div,
apply div_lt_of_mul_lt_of_pos,
repeat {assumption}
end

lemma rat_gt' {a b c : ℚ} (h : a > c*b) (hb : b > 0) : a / b > c :=
begin
apply lt_div_of_mul_lt,
repeat {assumption}
end

lemma rat_gt'' {a b c : ℚ} (h : a*c > b) (hb : c > 0) : a > b / c :=
begin
apply div_lt_of_mul_lt_of_pos,
repeat {assumption}
end

lemma eqs_gt_trans {a b c d : ℚ} (ha : a = b) (hc : c = d) (h : b > d) : a > c :=
by cc

lemma eq_gt_trans {a b c : ℚ} (ha : a = b) (h : b > c) : a > c :=
by cc

lemma eq_gt_trans' {a b c : ℚ} (ha : a = b) (h : c > b) : c > a :=
by cc

meta def mk_rat_gt_pf (mk_rat_ge_prf : expr → expr → tactic expr) : expr → expr → tactic expr
| `(%%a / %%b) `(%%c / %%d) := 
  do (lhs, lprf) ← norm_num `(%%a * %%d : ℚ),
     (rhs, rprf) ← norm_num `(%%c * %%b : ℚ),
     gtpf ← mk_gt_prf mk_rat_ge_prf lhs rhs,
     gtpf' ← mk_app `eqs_gt_trans [lprf, rprf, gtpf],
     bs ← mk_gt_prf mk_rat_ge_prf b `(0 : ℚ),
     ds ← mk_gt_prf mk_rat_ge_prf d `(0 : ℚ),
     mk_app ``rat_gt [gtpf', bs, ds]
| `(%%a / %%b) c :=
  do (lhs, lprf) ← norm_num `(%%c * %%b : ℚ),
     gtpf ← mk_gt_prf mk_rat_ge_prf a lhs,
     gtpf' ← mk_app `eq_gt_trans' [lprf, gtpf],
     bs ← mk_gt_prf mk_rat_ge_prf b `(0 : ℚ),
     mk_app ``rat_gt' [gtpf', bs]
| a `(%%b / %%c) :=
  do (lhs, lprf) ← norm_num `(%%a * %%c : ℚ),
     gtpf ← mk_rat_gt_pf lhs b,
     trace "a1",
     gtpf' ← mk_app `eq_gt_trans [lprf, gtpf],
     trace "a2",
     bs ← mk_gt_prf mk_rat_ge_prf c `(0 : ℚ),
     trace ("a3", a, b, c), infer_type gtpf' >>= trace, infer_type bs >>= trace,
     mk_app ``rat_gt'' [gtpf', bs]
| a b := trace "!!!!" >> trace a >> trace b >> mk_gt_prf mk_rat_ge_prf a b--fail "mk_rat_gt_pf failed"


meta def mk_rat_ge_prf : expr → expr → tactic expr := λ e1 e2,
(guard (e1 = e2) >> to_expr ``((le_refl _ : %%e1 ≥ %%e2))) <|> do
  gtprf ← mk_rat_gt_pf mk_rat_ge_prf e1 e2,
  trace "mk_rat_ge_prf:", infer_type gtprf >>= trace,
  l ← mk_app `le_of_lt [gtprf],
  infer_type l >>= trace,
  return l


meta def mk_gt_prf' (lhs rhs : expr) : tactic expr :=
do tp ← infer_type lhs,
   if tp = `(ℚ) then mk_rat_gt_pf mk_rat_ge_prf lhs rhs else mk_gt_prf @mk_ge_prf lhs rhs

meta def mk_ge_prf' (lhs rhs : expr) : tactic expr :=
do tp ← infer_type lhs,
   if tp = `(ℚ) then mk_rat_ge_prf lhs rhs else mk_ge_prf lhs rhs

-- assumes ≥ or > and already normalized
meta def gen_comp_val_prf : expr → tactic expr
| `(@has_le.le %%_ %%_ %%lhs %%rhs) := to_expr ``(%%rhs ≥ %%lhs) >>= gen_comp_val_prf
| `(@has_lt.lt %%_ %%_ %%lhs %%rhs) := to_expr ``(%%rhs > %%lhs) >>= gen_comp_val_prf
| `(@ge %%_ %%_ %%lhs %%rhs) := mk_ge_prf' lhs rhs
| `(@gt %%_ %%_ %%lhs %%rhs) := mk_gt_prf' /-mk_ge_prf-/ lhs rhs
| _ := tactic.fail "comp_val' didn't match"

meta def is_num : expr → bool
| `(@bit0 %%_ %%_ %%t) := is_num t
| `(@bit1 %%_ %%_ %%_ %%t) := is_num t
| `(@has_zero.zero %%_ %%_) := tt
| `(@has_one.one %%_ %%_) := tt
| _ := ff

meta def is_signed_num : expr → bool
| `(-%%a) := is_num a
| a := is_num a

#check @rewrite_core


meta def gen_comp_val : tactic unit := 
do t ← target,
   [_, _, lhs, rhs] ← return $ get_app_args t,
   if is_num lhs then
      if is_num rhs then gen_comp_val_prf t >>= apply
      else do (rhs', prf) ← norm_num rhs, rewrite_target prf, target >>= gen_comp_val_prf >>= apply
   else 
      do (lhs', prfl) ← norm_num lhs, rewrite_target prfl,
      if is_num rhs then do trace "here", trace_state, t ← target, t ← gen_comp_val_prf t, trace "now here", infer_type t >>= trace, failed-- exact t
      else do (rhs', prf) ← norm_num rhs, rewrite_target prf, t ← target >>= gen_comp_val_prf, apply t


meta def make_expr_into_num : expr → tactic expr := λ e, 
do t ← infer_type e,
   (do onet ← to_expr ``(1 : %%t), unify e onet, return onet) <|>
   (do zerot ← to_expr ``(0 : %%t), unify e zerot, return zerot) <|>
   (do m ← mk_meta_var t, 
       b0m ← to_expr ``(bit0 %%m), 
       unify e b0m, 
       m' ← make_expr_into_num m, 
       to_expr ``(bit0 %%m')) <|>
   (do m ← mk_meta_var t, 
       b1m ← to_expr ``(bit1 %%m), 
       unify e b1m, 
       m' ← make_expr_into_num m, 
       to_expr ``(bit1 %%m')) <|>
   (do m ← mk_meta_var t, 
       negm ← to_expr ``(- %%m), 
       unify e negm, 
       rv ← make_expr_into_num m, 
       to_expr ``(- %%rv))

meta def make_expr_into_rat (e : expr) : tactic expr := 
make_expr_into_num e <|> 
do t ← infer_type e,
   num ← mk_meta_var t, den ← mk_meta_var t,
   to_expr ``(%%num / %%den) >>= unify e,
   num' ← make_expr_into_num num, den' ← make_expr_into_num den,
   to_expr ``(%%num' / %%den')

meta def make_expr_into_mul (e : expr) : tactic expr := 
do t ← infer_type e,
   m1 ← mk_meta_var t, m2 ← mk_meta_var t,
   to_expr ``(%%m1 * %%m2) >>= unify e,
   lhs ← make_expr_into_rat m1, rhs ← make_expr_into_rat m2,
   to_expr ``(%%lhs * %%rhs)

meta def make_expr_into_sum : expr → tactic expr := λ e,
(do t ← infer_type e,
    m1 ← mk_meta_var t, m2 ← mk_meta_var t,
    to_expr ``(%%m1 + %%m2) >>= unify e,
    lhs ← make_expr_into_sum m1, rhs ← make_expr_into_sum m2,
    to_expr ``(%%lhs + %%rhs)) 
<|> 
(make_expr_into_mul e)

meta def make_expr_into_eq_zero (e : expr) : tactic expr :=
do m0 ← mk_mvar, m1 ← mk_mvar, m2 ← mk_mvar, 
   to_expr ``(@eq %%m1 %%m0 (@has_zero.zero %%m1 %%m2))>>= unify e,
   return m0


set_option profiler true
example : (198 : ℚ) / 100 ≤ 2 :=
by gen_comp_val--btrivial
