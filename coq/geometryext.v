Require Import ssreflect ssrbool ssrfun seq eqtype ssralg fintype finfun zmodp.
Require Import ssrint rat ssrnum ssrnat matrix. 
Require Import Relations.

Require Import syn model sem.

Set Implicit Arguments.
Unset Strict Implicit.
Import Prenex Implicits.


(*---------------------------------------------------------------------------
   Example: translations and change of basis
   This is currently Example 7 in the paper.
   ---------------------------------------------------------------------------*)
Inductive ExSrt := 
(* 2-d translations *)
|  T2 
(* 2-d linear transformations  *)
| GL2 
(* 1-d linear transformations, i.e. scalings and change of sign *)
| GL1 
(* 2-d orthogonal transformations, i.e. rotations and reflections *)
| O2.

Inductive ExPrimType := Vec | Scalar.

(* Index operations *)
Inductive ExIndexOp := 
| T2Add | T2Neg | T2Zero  
| GL2One | GL2Mul | GL2Inv
| GL1One | GL1Mul | GL1Inv
| O2One | O2Mul | O2Inv
| O2Inj | GL2Det | GL1Inj | GL1Abs.

(* Signature *)
Canonical ExSIG := mkSIG
  (fun i => match i with 
  | T2Add => ([:: T2; T2], T2)
  | T2Neg => ([:: T2], T2)
  | T2Zero => ([::], T2) 

  | GL2One => ([::], GL2)
  | GL2Mul => ([:: GL2; GL2], GL2)
  | GL2Inv => ([:: GL2], GL2)

  | GL1One => ([::], GL1)
  | GL1Mul => ([:: GL1; GL1], GL1)
  | GL1Inv => ([:: GL1], GL1)
  | GL1Inj => ([::GL1], GL2)

  | GL2Det => ([::GL2], GL1)
  | GL1Abs => ([::GL1], GL1)

  | O2One => ([::], O2)
  | O2Mul => ([:: O2; O2], O2)
  | O2Inv => ([:: O2], O2)
  | O2Inj => ([:: O2], GL2)

  end)
  (fun t => match t with 
  | Vec => [::GL2;T2] 
  | Scalar => [::GL1] 
  end).

Open Scope Ty_scope.

(* We have so many theories here that it's easiest to parameterize a bit *)
Definition AGAxioms (s: Srt ExSIG) 
  (unit: forall D, Exp D s)
  (op: forall D, Exp D s -> Exp D s -> Exp D s) 
  (inv: forall D, Exp D s -> Exp D s) : seq (Ax ExSIG) :=
[::
  (* right identity *)
  [::s] |- op _ #0 (unit _) === #0;

  (* commutativity *)
  [::s;s] |- op _ #0 #1 === op _ #1 #0;

  (* associativity *)
  [::s;s;s] |- op _ #0 (op _ #1 #2) === op _ (op _ #0 #1) #2;

  (* right inverse *)
  [::s] |- op _ #0 (inv _ #0) === unit _ 
].

Definition GroupAxioms (s: Srt ExSIG) 
  (unit: forall D, Exp D s) 
  (op: forall D, Exp D s -> Exp D s -> Exp D s) 
  (inv: forall D, Exp D s -> Exp D s) : seq (Ax ExSIG) :=
[::
  (* right identity *)
  [::s] |- op _ #0 (unit _) === #0;

  (* left identity *)
  [::s] |- op _ (unit _) #0 === #0;

  (* associativity *)
  [::s;s;s] |- op _ #0 (op _ #1 #2) === op _ (op _ #0 #1) #2;

  (* right inverse *)
  [::s] |- op _ #0 (inv _ #0) === unit _;

  (* left inverse *)
  [::s] |- op _ (inv _ #0) #0 === unit _ 
].
  
Definition HomAxioms (s s': Srt ExSIG) 
  (h: forall D, Exp D s -> Exp D s') 
  (op: forall D, Exp D s -> Exp D s -> Exp D s)
  (op': forall D, Exp D s' -> Exp D s' -> Exp D s') :=
[::
  [::s;s] |- h _ (op _ #0 #1) === op' _ (h _ #0) (h _ #1)
].

Open Scope Exp_scope.
Definition ExAxioms : seq (Ax ExSIG) :=

(* additive AG for translations *)
  AGAxioms (fun D => T2Zero<>) (fun D u v => T2Add<u,v>) (fun D u => T2Neg<u>) ++

(* multiplicative group for GL2 *)
  GroupAxioms (fun D => GL2One<>) (fun D u v => GL2Mul<u,v>) (fun D u => GL2Inv<u>) ++ 

(* multiplicative group for O2 *)
  GroupAxioms (fun D => O2One<>) (fun D u v => O2Mul<u,v>) (fun D u => O2Inv<u>) ++ 

(* multiplicative AG for GL1 *)
  AGAxioms (fun D => GL1One<>) (fun D u v => GL1Mul<u,v>) (fun D u => GL1Inv<u>) ++

(* det is homomorphism *)
  HomAxioms (fun D u => GL2Det<u>) (fun D u v => GL2Mul<u,v>) (fun D u v => GL1Mul<u,v>) ++

(* abs is homomorphism *)
  HomAxioms (fun D u => GL1Abs<u>) (fun D u v => GL1Mul<u,v>) (fun D u v => GL1Mul<u,v>) ++

(* inj: GL1 -> GL2 is homomorphism *)
  HomAxioms (fun D u => GL1Inj<u>) (fun D u v => GL1Mul<u,v>) (fun D u v => GL2Mul<u,v>) ++

(* inj: O2 -> GL2 is homomorphism *)
  HomAxioms (fun D u => O2Inj<u>) (fun D u v => O2Mul<u,v>) (fun D u v => GL2Mul<u,v>).

Definition trEquiv D : relation (Exp D T2) := equiv ExAxioms.
Definition glEquiv D : relation (Exp D GL2) := equiv ExAxioms.

Definition Point D (B:Exp D GL2) := Vec.<B,T2Zero<>>.

Definition Gops : Ctxt [::] :=
[::
  (* 0 *)
  all GL2 (Point #0);

  (* + *)
  all T2 (all T2 (all GL2 (Vec.<#0, #1> --> Vec.<#0, #2> --> Vec.<#0, (T2Add<#1,#2>)>)));

  (* negate *)
  all T2 (all GL2 (Vec.<#0,#1> --> Vec.<#0, (T2Neg<#1>)>));

  (* * *)
  all GL2 (Scalar.<GL1One<>> --> Vec.<#0,T2Zero<>> --> Vec.<#0, T2Zero<>>);

  (* cross *)
  all GL2 (Vec.<#0,T2Zero<>> --> Vec.<#0,T2Zero<>> --> Scalar.<(GL2Det<#0>)>);

  (* dot *)
  all O2 (Vec.<O2Inj<#0>, T2Zero<>> --> Vec.<O2Inj<#0>, T2Zero<>> --> Scalar.<GL1One<>>)
].

Variable F: numFieldType.

(* n-vector of F *)
Notation "''vec_' n" := ('cV[F]_n) (at level 8, n at level 2, format "''vec_' n").

Definition interpPrim p := match p with Vec => 'vec_2 | Scalar => F end.

Open Scope ring_scope.

(* Cross product for 2-d vectors is just the determinant of the vectors pasted together *)
Definition cross (v w: 'vec_2) := \det (row_mx v w). 

(* Dot product *)
Definition dot (v w: 'vec_2) := (v^T *m w) 0 0. 

Definition eta_ops : interpCtxt interpPrim Gops :=
  (0%R, (+%R, (-%R, ( *:%R, (cross, (dot, tt)))))). 

(*---------------------------------------------------------------------------
   Our first relational interpretation: translations and change of basis
   ---------------------------------------------------------------------------*)

(*---------------------------------------------------------------------------
   Matrices representing the general linear group GL(n) over the field F
   ---------------------------------------------------------------------------*)
Section GL.

  Variable n: nat.

  Definition invertible (m: matrix_unitRing F n.-1) := m \in unitmx.

  (* The type itself; a matrix over F and a proof that it is invertible *)
  Structure GL_type := mkGL {tval :> matrix_unitRing F n.-1; _ : invertible tval}.

  Canonical GL_subType := Eval hnf in [subType for tval by GL_type_rect].
  Definition GL_eqMixin := Eval hnf in [eqMixin of GL_type by <:]. 
  Canonical GL_eqType := Eval hnf in EqType GL_type GL_eqMixin.  

  Lemma GL_unit (x: GL_type) : invertible (val x). Proof. by elim x. Qed.

  Lemma GL_inj (x y: GL_type) : val x = val y -> x = y. 
  Proof. by move /val_inj ->. Qed. 

  (* Group operations: 1, * and ^-1. Also the determinant into F *)
  Definition GL_one := mkGL (unitmx1 _ _). 

  Lemma GL_mulP (x y: GL_type) : invertible (val x *m val y).
  Proof. rewrite /invertible unitmx_mul. by destruct x; destruct y; intuition. Qed. 
  Definition GL_mul x y := mkGL (GL_mulP x y).  

  Lemma GL_invP (x: GL_type) : invertible (invmx (val x)). 
  Proof. rewrite /invertible unitmx_inv. by destruct x. Qed. 
  Definition GL_inv x := mkGL (GL_invP x). 

End GL.

Notation "''GL_' n" := (GL_type n) (at level 8, n at level 2, format "''GL_' n").

(*---------------------------------------------------------------------------
   Matrices representing the orthogonal group O(n) over the field F
   ---------------------------------------------------------------------------*)
Section O.

  Variable n: nat.

  Definition orthogonal (m: 'GL_n) := (val m)^T == (val m)^-1.

  (* The type itself *)
  Structure O_type : Type := mkO {oval:> 'GL_n; _ : orthogonal oval }.

  Canonical O_subType := [subType for oval by O_type_rect].
  Definition O_eqMixin := Eval hnf in [eqMixin of O_type by <:]. 
  Canonical O_eqType := Eval hnf in EqType O_type O_eqMixin.  

  Lemma O_orth (x: O_type) : orthogonal x. Proof. by elim x. Qed.

  Lemma O_inj (x y: O_type) : val x = val y -> x = y. 
  Proof. by move /val_inj ->. Qed. 

  (* Group operations: 1, * and ^-1 *)
  Lemma O_oneP : orthogonal (GL_one n). 
  Proof. rewrite /GL_one/orthogonal/=. by rewrite trmx1 GRing.invr1. Qed. 

  Definition O_one := mkO O_oneP.

  Lemma O_mulP (x y: O_type) : orthogonal (GL_mul (oval x) (oval y)).  
  Proof. rewrite /GL_mul/orthogonal/=. rewrite trmx_mul. 
  destruct x as [x xH]. destruct y as [y yH].
  simpl. rewrite /orthogonal in xH, yH. rewrite (eqP xH) (eqP yH).
  rewrite /= GRing.invrM => //. 
  apply (GL_unit x). apply (GL_unit y). 
  Qed. 
  Definition O_mul x y := mkO (O_mulP x y). 

  Lemma O_invP (x: O_type) : orthogonal (GL_inv (oval x)). 
  Proof. rewrite /GL_inv/orthogonal/=. rewrite trmx_inv.
  destruct x as [x xH]. simpl. rewrite /orthogonal in xH. by rewrite (eqP xH). 
  Qed.   
  Definition O_inv x := mkO (O_invP x). 

End O. 

Definition toScalar (x: 'GL_1) : F := val x 0 0. 

Notation "''O_' n" := (O_type n) (at level 8, n at level 2, format "''O_' n").

Lemma GL_detP n (x: 'GL_n) : invertible (n:=1) (scalar_mx (determinant (val x))).  
Proof. destruct x as [x xH]. simpl. rewrite /invertible in xH. rewrite unitmxE in xH. 
by rewrite /invertible unitmxE det_scalar1. 
Qed. 
Definition GL_det n (x: 'GL_n) : 'GL_1 := mkGL (GL_detP x).

Lemma GL1_absP (x: 'GL_1) : invertible (n:=1) (scalar_mx (`|toScalar x|)). 
Proof. rewrite /invertible. destruct x as [x xH]. rewrite /toScalar/=.
rewrite unitmxE. rewrite /invertible in xH. rewrite unitmxE in xH. simpl in x.
rewrite det_scalar1. rewrite Num.Theory.normr_unit => //.
rewrite (mx11_scalar x) in xH. by rewrite det_scalar1 in xH.
Qed. 
Definition GL1_abs (x: 'GL_1) := mkGL (GL1_absP x). 

Lemma O_injP n (x: 'O_n) : invertible (val x). 
Proof. destruct x as [x xH]. by destruct x.  Qed. 
Definition O_injGL n (x: 'O_n) := mkGL (O_injP x). 

Lemma GL1_injP n (x: 'GL_1) : invertible (n:=n) (scalar_mx (toScalar x)).
Proof. rewrite /invertible/toScalar/=.
destruct x as [x xH]. simpl. rewrite /invertible in xH.
simpl in x, xH.
rewrite unitmxE det_scalar. simpl. 
rewrite unitmxE (mx11_scalar x) det_scalar GRing.expr1 in xH. 
rewrite GRing.unitrX => //. 
Qed. 
Definition GL1_inj n (x: 'GL_1) : 'GL_n := mkGL (GL1_injP n x). 

Definition interpSrt s := 
  match s with 
  | T2 => 'vec_2 
  | GL2 => 'GL_2 
  | GL1 => 'GL_1 
  | O2 => 'O_2
  end.

Definition TransformInterpretation := mkInterpretation
  (interpSrt := interpSrt)
  (fun p =>
   match p return Env interpSrt (opArity p).1 -> interpSrt (opArity p).2 with
     T2Zero  => fun args => 0%R
   | T2Add   => fun args => args.1 + args.2.1
   | T2Neg   => fun args => -args.1

   | GL2Mul  => fun args => GL_mul args.1 args.2.1
   | GL2Inv  => fun args => GL_inv args.1
   | GL2One  => fun args => GL_one _

   | GL1Mul  => fun args => GL_mul args.1 args.2.1
   | GL1Inv  => fun args => GL_inv args.1
   | GL1One  => fun args => GL_one _

   | O2Mul   => fun args => O_mul args.1 args.2.1
   | O2Inv   => fun args => O_inv args.1
   | O2One   => fun args => O_one _
   | O2Inj   => fun args => O_injGL args.1

   | GL2Det  => fun args => GL_det args.1
   | GL1Inj  => fun args => GL1_inj 2 args.1
   | GL1Abs  => fun args => GL1_abs args.1
   end ).


Hint Resolve GL_inj. 

Definition TransformModel : Model ExAxioms. 
Proof. 
apply (@mkModel _ ExAxioms TransformInterpretation). 
split. 
(*------------------------ additive AG for translations -----------------------*)
(* right identity *)
move => /= [x _] /=. by rewrite GRing.addr0. 
split. 
(* commutativity *)
move => /= [x [y _]] /=. by rewrite GRing.addrC. 
split. 
(* associativity *)
move => /= [x [y [z _]]] /=. by rewrite GRing.addrA. 
split. 
(* right inverse *)
move => /= [x _] /=. by rewrite GRing.addrN. 
split.
(*------------------------  multiplicative group for GL2 ---------------------*)
(* right identity *)
move => /= [x _] /=.
apply GL_inj. 
by rewrite /= mulmx1.
split. 
(* left identity *)
move => /= [x _] /=.
apply GL_inj.
by rewrite /= mul1mx.
split. 
(* associativity *)
move => /= [x [y [z _]]] /=. 
apply GL_inj.
by rewrite /= mulmxA. 
split. 
(* right inverse *)
move => /= [x _] /=. 
apply GL_inj. 
rewrite /= mulmxV => //. by elim x. 
split.
(* left inverse *)
move => /= [x _] /=. 
apply GL_inj. 
rewrite /= mulVmx => //. by elim x. 
split.
(*-------------------------- multiplicative group for O2 ---------------------- *)
(* right identity *)
move => /= [x _] /=.
apply O_inj; apply GL_inj. 
by rewrite /= mulmx1.
split. 
(* left identity *)
move => /= [x _] /=.
apply O_inj; apply GL_inj.
by rewrite /= mul1mx.
split. 
(* associativity *)
move => /= [x [y [z _]]] /=. 
apply O_inj; apply GL_inj.
by rewrite /= mulmxA. 
split. 
(* right inverse *)
move => [x _] /=. 
apply O_inj; apply GL_inj. 
rewrite /= mulmxV => //. by elim x; elim.  
split.
(* left inverse *)
move => /= [x _] /=. 
apply O_inj; apply GL_inj.
rewrite /= mulVmx => //. by elim x; elim. 
split.

(*---------------------------- multiplicative AG for GL1 ------------------------*)
(* right identity for GL1 *)
move => /= [x _] /=.
apply GL_inj. 
by rewrite /= mulmx1.
split. 
(* commutativity *)
move => /= [x [y _]] /=. 
apply GL_inj. 
elim: x => /= [x xinv] /=. 
elim: y => /= [y yinv] /=. 
(* This seems very long-winded! *)
rewrite (mx11_scalar x) (mx11_scalar y).
by rewrite -!scalar_mxM GRing.mulrC. 
split.
(* associativity *)
move => /= [x [y [z _]]] /=. 
apply GL_inj.
by rewrite /= mulmxA. 
split. 
(* right inverse *)
move => [x _] /=. 
apply GL_inj. 
rewrite /= mulmxV => //. by elim x. 
split.

(* det is homomorphism *)
move => /= [x [y _]] /=. 
apply GL_inj. 
rewrite /= det_mulmx/=. 
by rewrite scalar_mx_is_multiplicative. 
split. 
(* abs is homomorphism *)
move => /= [x [y _]] /=.
apply GL_inj. simpl. 
unfold toScalar. (* Weirdly, rewrite /toScalar doesn't unfold *)
elim: x => /= [x xinv]. 
elim: y => /= [y yinv]. 
rewrite -scalar_mxM -Num.Theory.normrM. 
apply f_equal. 
(* Here we unfold the definition of matrix multiplication. This shouldn't be necessary *)
rewrite mxE. by rewrite big_ord1. 
split. 
(* inj: GL1 -> GL2 is homomorphism *)
move => /= [x [y _]] /=.
apply GL_inj. simpl. 
unfold toScalar. (* Weirdly, rewrite /toScalar doesn't unfold *)
elim: x => /= [x xinv]. 
elim: y => /= [y yinv]. 
rewrite -scalar_mxM.  
apply f_equal. 
(* Here we unfold the definition of matrix multiplication. This shouldn't be necessary *)
rewrite mxE. by rewrite big_ord1. 
split.
(* inj: O2 -> GL2 is homomorphism *)
move => /= [x [y _]] /=.
by apply GL_inj. 
split.
Defined. 

Definition transformBy (B: 'GL_2) (t v: 'vec_2) := val B *m v + t. 

Definition TransformModelEnv := mkModelEnv (interpPrim := interpPrim) (M:=TransformModel)
  (fun X => 
    match X with 
    | Scalar => fun args => fun x y => y = x * determinant (val args.1)
    | Vec    => fun args => fun v w => w = transformBy args.1 args.2.1 v 
    end). 

Definition transformSemTy D := semTy (ME:=TransformModelEnv) (D:=D).

Definition initialTransformEnv: RelEnv TransformModelEnv [::] := tt. 

(* Interpretation of pervasives preserve translation relations *)
Lemma eta_ops_ok : semCtxt initialTransformEnv eta_ops eta_ops.
Proof.
split. 
(* 0 *)
move => k. 
rewrite /=/transformBy. 
by rewrite GRing.addr0 mulmx0. 
split.
(* + *)
move => /= t t' B x x' -> y y' ->.
rewrite /transformBy.
rewrite mulmxDr. 
rewrite -!GRing.addrA. 
by rewrite (GRing.addrCA t'). 
split. 
(* negate *)
move => /= t B x x' ->.
rewrite /transformBy. 
rewrite GRing.opprD. 
by rewrite -mulmxN. 
split. 
(* mul *)
move => /= B x x' -> y y' ->.
rewrite /transformBy.
rewrite 2!GRing.addr0. 
rewrite det1 GRing.mulr1. 
by rewrite -scalemxAr. 
split. 
(* cross *)
move => /= B x x' -> y y' ->.
rewrite /cross/transformBy.  
rewrite !GRing.addr0 /=. 
rewrite det_scalar1.
rewrite -!mul_mx_row. rewrite !det_mulmx. by rewrite GRing.mulrC. 
split.
(* dot *)
move => /= B x x' -> y y' ->.
rewrite /dot/transformBy/=. 
rewrite det1 !GRing.addr0 GRing.mulr1. 
rewrite trmx_mul. 
rewrite mulmxA -(mulmxA x^T). elim: B => [B orthB] /=. 
rewrite /orthogonal/= in orthB. rewrite (eqP orthB). 
rewrite mulVmx. by rewrite mulmx1. by elim B. 
split. 
Qed. 
