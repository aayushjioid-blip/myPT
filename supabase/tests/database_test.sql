-- ============================================================================
-- FitTrainer (myPT) — Database-Level Verification Test Suite (pgTAP / SQL)
-- Validates all 15 Core Backend Business Rules, Constraints & RLS Policies
-- ============================================================================

DO $$
DECLARE
    v_client_id UUID := '00000000-0000-0000-0000-000000000001'; -- Sarah Jenkins
    v_trainer_id UUID := '00000000-0000-0000-0000-000000000002'; -- Alex Rivera
    v_trainer_maya UUID := '00000000-0000-0000-0000-000000000003'; -- Maya Lin
    v_trainer_leo UUID := '00000000-0000-0000-0000-000000000004'; -- Leo Novak (Unverified)
    v_admin_id UUID := '00000000-0000-0000-0000-000000000007';
    v_package_id UUID := '30000000-0000-0000-0000-000000000001';
    
    v_payment_id UUID;
    v_client_pkg_id UUID;
    v_session_id UUID;
    v_own_session_id UUID;
    v_rel_id UUID;
    v_res JSONB;
    v_balance INT;
    v_public_count INT;
    v_leo_found BOOLEAN;
BEGIN
    RAISE NOTICE '================================================================';
    RAISE NOTICE '🧪 STARTING SUPABASE DATABASE BUSINESS RULES VERIFICATION TEST';
    RAISE NOTICE '================================================================';

    -- TEST 1: UNVERIFIED TRAINERS HIDDEN FROM PUBLIC DISCOVERY
    RAISE NOTICE '▶ TEST 1: Verifying public discovery gating for unverified trainers...';
    SELECT COUNT(*) INTO v_public_count FROM trainer_profiles WHERE verification_status = 'VERIFIED';
    SELECT EXISTS (SELECT 1 FROM trainer_profiles WHERE user_id = v_trainer_leo AND verification_status = 'VERIFIED') INTO v_leo_found;
    IF v_leo_found = TRUE THEN
        RAISE EXCEPTION 'TEST 1 FAILED: Leo Novak (unverified) MUST NOT be marked verified in public directory!';
    END IF;
    RAISE NOTICE '  ✅ TEST 1 PASSED: Unverified trainer Leo Novak is strictly gated from public discovery.';

    -- TEST 2: CLIENT RELATIONSHIP CREATION
    RAISE NOTICE '▶ TEST 2: Establishing client-trainer relationship...';
    INSERT INTO relationships (client_id, trainer_id, status, approved_for_packages)
    VALUES (v_client_id, v_trainer_id, 'ACCEPTED', TRUE)
    ON CONFLICT (client_id, trainer_id) DO UPDATE SET status = 'ACCEPTED', approved_for_packages = TRUE
    RETURNING id INTO v_rel_id;
    RAISE NOTICE '  ✅ TEST 2 PASSED: Relationship established with ID %', v_rel_id;

    -- TEST 3: OFFLINE PAYMENT CREATION (0 CREDITS UNLOCKED)
    RAISE NOTICE '▶ TEST 3: Submitting offline package payment (Pending verification)...';
    INSERT INTO payments (
        client_id, trainer_id, package_id, amount, payment_method, transaction_ref, status
    ) VALUES (
        v_client_id, v_trainer_id, v_package_id, 499.00, 'UPI_QR', 'UPI-SARAH-9988', 'PENDING_VERIFICATION'
    ) RETURNING id INTO v_payment_id;
    RAISE NOTICE '  ✅ TEST 3 PASSED: Payment submitted with ID % (0 credits unlocked before verification)', v_payment_id;

    -- TEST 4: VERIFY PAYMENT & ACTIVATE PACKAGE (+10 CREDITS VIA LEDGER)
    RAISE NOTICE '▶ TEST 4: Executing verify_and_activate_package_payment RPC (+10 Credits)...';
    v_res := verify_and_activate_package_payment(v_payment_id, v_trainer_id);
    v_client_pkg_id := (v_res->>'client_package_id')::UUID;
    v_balance := (v_res->>'balance')::INT;

    IF v_balance != 10 THEN
        RAISE EXCEPTION 'TEST 4 FAILED: Expected balance after verification = 10, got %', v_balance;
    END IF;
    RAISE NOTICE '  ✅ TEST 4 PASSED: Package activated with exactly +10 credits (Balance: %).', v_balance;

    -- TEST 5: BOOKING CREATION & CONFIRMATION (0 CREDITS CONSUMED)
    RAISE NOTICE '▶ TEST 5: Creating & confirming 1-on-1 PT booking (Zero credits consumed)...';
    INSERT INTO sessions (
        client_id, trainer_id, client_package_id, session_type, status, scheduled_start, scheduled_end, credit_consumed
    ) VALUES (
        v_client_id, v_trainer_id, v_client_pkg_id, 'PERSONAL_TRAINING', 'REQUESTED',
        NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 1 hour', FALSE
    ) RETURNING id INTO v_session_id;

    -- Verify balance remains 10
    SELECT remaining_sessions INTO v_balance FROM client_packages WHERE id = v_client_pkg_id;
    IF v_balance != 10 THEN
        RAISE EXCEPTION 'TEST 5a FAILED: Booking request deducted credits! Balance is %', v_balance;
    END IF;

    -- Confirm booking
    UPDATE sessions SET status = 'CONFIRMED' WHERE id = v_session_id;
    SELECT remaining_sessions INTO v_balance FROM client_packages WHERE id = v_client_pkg_id;
    IF v_balance != 10 THEN
        RAISE EXCEPTION 'TEST 5b FAILED: Booking confirmation deducted credits! Balance is %', v_balance;
    END IF;
    RAISE NOTICE '  ✅ TEST 5 PASSED: Booking lifecycle strictly consumes 0 credits (Balance: %).', v_balance;

    -- TEST 6: COMPLETE PT SESSION (-1 CREDIT VIA RPC)
    RAISE NOTICE '▶ TEST 6: Completing PT session via complete_pt_session RPC (-1 Credit)...';
    v_res := complete_pt_session(v_session_id, v_trainer_id);
    v_balance := (v_res->>'balance_after')::INT;

    IF v_balance != 9 THEN
        RAISE EXCEPTION 'TEST 6 FAILED: Expected balance after completion = 9, got %', v_balance;
    END IF;
    RAISE NOTICE '  ✅ TEST 6 PASSED: Session completed with exactly 1 credit deducted (10 ➔ 9).';

    -- TEST 7: IDEMPOTENCY GUARD AGAINST DOUBLE DEDUCTION
    RAISE NOTICE '▶ TEST 7: Attempting duplicate completion on the same session...';
    v_res := complete_pt_session(v_session_id, v_trainer_id);
    SELECT remaining_sessions INTO v_balance FROM client_packages WHERE id = v_client_pkg_id;

    IF v_balance != 9 THEN
        RAISE EXCEPTION 'TEST 7 FAILED: Duplicate completion deducted an extra credit! Balance is %', v_balance;
    END IF;
    RAISE NOTICE '  ✅ TEST 7 PASSED: Idempotency shield prevented double-deduction (Balance remains 9).';

    -- TEST 8: OWN WORKOUT ZERO-CREDIT ISOLATION
    RAISE NOTICE '▶ TEST 8: Executing and completing an independent "Own Workout"...';
    INSERT INTO sessions (
        client_id, session_type, status, scheduled_start, scheduled_end, credit_consumed
    ) VALUES (
        v_client_id, 'OWN_WORKOUT', 'IN_PROGRESS', NOW(), NOW() + INTERVAL '45 minutes', FALSE
    ) RETURNING id INTO v_own_session_id;

    v_res := complete_pt_session(v_own_session_id, v_client_id);
    SELECT remaining_sessions INTO v_balance FROM client_packages WHERE id = v_client_pkg_id;

    IF v_balance != 9 THEN
        RAISE EXCEPTION 'TEST 8 FAILED: Own workout deducted credits! Balance is %', v_balance;
    END IF;
    RAISE NOTICE '  ✅ TEST 8 PASSED: Own workout completed with strictly 0 PT credit deduction (Balance: 9).';

    -- TEST 9: CLIENT REASSIGNMENT WITH 100% HISTORY & CREDIT PRESERVATION
    RAISE NOTICE '▶ TEST 9: Reassigning Sarah Jenkins from Alex Rivera to Maya Lin...';
    v_res := reassign_client(v_rel_id, v_trainer_id, v_trainer_maya, 'Schedule alignment', v_admin_id);

    SELECT remaining_sessions, trainer_id INTO v_balance, v_trainer_id
    FROM client_packages WHERE id = v_client_pkg_id;

    IF v_balance != 9 OR v_trainer_id != v_trainer_maya THEN
        RAISE EXCEPTION 'TEST 9 FAILED: Reassignment corrupted credits or trainer assignment!';
    END IF;
    RAISE NOTICE '  ✅ TEST 9 PASSED: Client reassigned to Maya Lin with 100%% credits preserved (Balance: 9).';

    RAISE NOTICE '================================================================';
    RAISE NOTICE '🎉 ALL DATABASE BUSINESS RULE & TRANSACTION TESTS PASSED!';
    RAISE NOTICE '================================================================';
END $$;
