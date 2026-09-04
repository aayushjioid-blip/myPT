-- ============================================================================
-- FitTrainer (myPT) — Migration 004: Stored Procedures & Business RPC Functions
-- ============================================================================

-- 1. VERIFY & ACTIVATE PACKAGE PAYMENT
CREATE OR REPLACE FUNCTION verify_and_activate_package_payment(
    p_payment_id UUID,
    p_verified_by UUID
)
RETURNS JSONB AS $$
DECLARE
    v_payment RECORD;
    v_package RECORD;
    v_client_package_id UUID;
    v_new_balance INT;
BEGIN
    -- 1. Lock and fetch payment record
    SELECT * INTO v_payment
    FROM payments
    WHERE id = p_payment_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment record % not found', p_payment_id;
    END IF;

    IF v_payment.status = 'VERIFIED' THEN
        RETURN jsonb_build_object('success', true, 'message', 'Payment was already verified');
    END IF;

    -- 2. Fetch package specifications
    SELECT * INTO v_package
    FROM packages
    WHERE id = v_payment.package_id;

    -- 3. Create or activate client package
    IF v_payment.client_package_id IS NOT NULL THEN
        UPDATE client_packages
        SET status = 'ACTIVE',
            total_sessions = v_package.sessions,
            remaining_sessions = v_package.sessions,
            activated_at = NOW(),
            expires_at = NOW() + (v_package.validity_days || ' days')::INTERVAL,
            updated_at = NOW()
        WHERE id = v_payment.client_package_id
        RETURNING id, remaining_sessions INTO v_client_package_id, v_new_balance;
    ELSE
        INSERT INTO client_packages (
            client_id,
            trainer_id,
            package_id,
            total_sessions,
            remaining_sessions,
            price_paid,
            status,
            activated_at,
            expires_at
        ) VALUES (
            v_payment.client_id,
            v_payment.trainer_id,
            v_payment.package_id,
            v_package.sessions,
            v_package.sessions,
            v_payment.amount,
            'ACTIVE',
            NOW(),
            NOW() + (v_package.validity_days || ' days')::INTERVAL
        ) RETURNING id, remaining_sessions INTO v_client_package_id, v_new_balance;

        UPDATE payments SET client_package_id = v_client_package_id WHERE id = p_payment_id;
    END IF;

    -- 4. Record Append-Only Credit Ledger Activation Transaction
    INSERT INTO credit_ledger_transactions (
        client_package_id,
        client_id,
        trainer_id,
        transaction_type,
        delta_credits,
        balance_after,
        reason,
        created_by
    ) VALUES (
        v_client_package_id,
        v_payment.client_id,
        v_payment.trainer_id,
        'PACKAGE_ACTIVATION',
        v_package.sessions,
        v_new_balance,
        'Payment verified: ' || v_package.name || ' (+' || v_package.sessions || ' credits)',
        p_verified_by
    );

    -- 5. Mark Payment Verified
    UPDATE payments
    SET status = 'VERIFIED',
        verified_at = NOW(),
        verified_by = p_verified_by,
        updated_at = NOW()
    WHERE id = p_payment_id;

    -- 6. Notify Client
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        reference_id,
        reference_type
    ) VALUES (
        v_payment.client_id,
        'Payment Verified & Package Activated! 🎉',
        'Your payment has been verified. ' || v_package.sessions || ' PT sessions are now active.',
        'PAYMENT',
        v_client_package_id,
        'CLIENT_PACKAGE'
    );

    RETURN jsonb_build_object(
        'success', true,
        'client_package_id', v_client_package_id,
        'activated_credits', v_package.sessions,
        'balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2. COMPLETE PT SESSION (ATOMIC & IDEMPOTENT CREDIT DEDUCTION)
CREATE OR REPLACE FUNCTION complete_pt_session(
    p_session_id UUID,
    p_completed_by UUID
)
RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_client_pkg RECORD;
    v_new_balance INT;
BEGIN
    -- 1. Lock and fetch session record
    SELECT * INTO v_session
    FROM sessions
    WHERE id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session % not found', p_session_id;
    END IF;

    -- IDEMPOTENCY GUARD: If already credit consumed, return immediately without double-deduction!
    IF v_session.credit_consumed = TRUE OR v_session.status = 'COMPLETED' THEN
        RETURN jsonb_build_object(
            'success', true,
            'message', 'Session was already completed. No duplicate credit deducted.',
            'credit_deducted', 0
        );
    END IF;

    -- ZERO-CREDIT OWN WORKOUT ISOLATION
    IF v_session.session_type = 'OWN_WORKOUT' THEN
        UPDATE sessions
        SET status = 'COMPLETED',
            actual_end = NOW(),
            credit_consumed = FALSE,
            updated_at = NOW()
        WHERE id = p_session_id;

        RETURN jsonb_build_object(
            'success', true,
            'message', 'Own Workout completed with 0 PT credits consumed.',
            'credit_deducted', 0
        );
    END IF;

    -- PERSONAL TRAINING: Deduct exactly 1 credit from active package
    IF v_session.client_package_id IS NULL THEN
        -- Find latest active package for client
        SELECT * INTO v_client_pkg
        FROM client_packages
        WHERE client_id = v_session.client_id
          AND status = 'ACTIVE'
          AND remaining_sessions > 0
        ORDER BY activated_at DESC
        LIMIT 1
        FOR UPDATE;
    ELSE
        SELECT * INTO v_client_pkg
        FROM client_packages
        WHERE id = v_session.client_package_id
        FOR UPDATE;
    END IF;

    IF v_client_pkg IS NULL OR v_client_pkg.remaining_sessions < 1 THEN
        RAISE EXCEPTION 'Client % has no available active PT session credits!', v_session.client_id;
    END IF;

    -- Calculate new balance
    v_new_balance := v_client_pkg.remaining_sessions - 1;

    -- Update client package balance
    UPDATE client_packages
    SET remaining_sessions = v_new_balance,
        status = CASE WHEN v_new_balance = 0 THEN 'EXHAUSTED'::client_package_status_type ELSE 'ACTIVE'::client_package_status_type END,
        updated_at = NOW()
    WHERE id = v_client_pkg.id;

    -- Record Append-Only Credit Ledger Transaction
    INSERT INTO credit_ledger_transactions (
        client_package_id,
        client_id,
        trainer_id,
        session_id,
        transaction_type,
        delta_credits,
        balance_after,
        reason,
        created_by
    ) VALUES (
        v_client_pkg.id,
        v_session.client_id,
        v_session.trainer_id,
        p_session_id,
        'SESSION_COMPLETION',
        -1,
        v_new_balance,
        'Completed 1-on-1 PT session (Session ID: ' || p_session_id || ')',
        p_completed_by
    );

    -- Mark session completed and credit consumed
    UPDATE sessions
    SET status = 'COMPLETED',
        credit_consumed = TRUE,
        actual_end = NOW(),
        updated_at = NOW()
    WHERE id = p_session_id;

    -- Low Credit Alert (<= 2 sessions remaining)
    IF v_new_balance <= 2 THEN
        INSERT INTO notifications (
            user_id,
            title,
            message,
            type,
            reference_id,
            reference_type
        ) VALUES (
            v_session.client_id,
            'Low PT Credits Warning ⚠️',
            'You have ' || v_new_balance || ' PT session(s) remaining with your coach.',
            'LOW_CREDIT',
            v_client_pkg.id,
            'CLIENT_PACKAGE'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'session_id', p_session_id,
        'credit_deducted', 1,
        'balance_after', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 3. APPLY CANCELLATION POLICY
CREATE OR REPLACE FUNCTION apply_cancellation_policy(
    p_session_id UUID,
    p_cancelled_by UUID,
    p_reason TEXT DEFAULT 'Cancelled by participant'
)
RETURNS JSONB AS $$
DECLARE
    v_session RECORD;
    v_trainer RECORD;
    v_client_pkg RECORD;
    v_hours_until_start NUMERIC;
    v_penalty_applied BOOLEAN := FALSE;
    v_new_balance INT;
BEGIN
    SELECT * INTO v_session
    FROM sessions
    WHERE id = p_session_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Session % not found', p_session_id;
    END IF;

    SELECT * INTO v_trainer
    FROM trainer_profiles
    WHERE user_id = v_session.trainer_id;

    -- Calculate difference in hours between now and scheduled start
    v_hours_until_start := EXTRACT(EPOCH FROM (v_session.scheduled_start - NOW())) / 3600.0;

    -- Rule: If cancelled by trainer -> 0 penalty
    IF p_cancelled_by = v_session.trainer_id THEN
        v_penalty_applied := FALSE;
    -- Rule: If cancelled by client inside grace window and penalty enabled -> Apply penalty
    ELSIF v_hours_until_start < COALESCE(v_trainer.cancellation_grace_hours, 4) AND COALESCE(v_trainer.late_cancellation_penalty_enabled, TRUE) THEN
        v_penalty_applied := TRUE;
    ELSE
        v_penalty_applied := FALSE;
    END IF;

    IF v_penalty_applied AND v_session.client_package_id IS NOT NULL THEN
        SELECT * INTO v_client_pkg
        FROM client_packages
        WHERE id = v_session.client_package_id
        FOR UPDATE;

        IF v_client_pkg.remaining_sessions > 0 THEN
            v_new_balance := v_client_pkg.remaining_sessions - COALESCE(v_trainer.late_cancellation_penalty_credits, 1);
            IF v_new_balance < 0 THEN v_new_balance := 0; END IF;

            UPDATE client_packages
            SET remaining_sessions = v_new_balance,
                updated_at = NOW()
            WHERE id = v_client_pkg.id;

            INSERT INTO credit_ledger_transactions (
                client_package_id,
                client_id,
                trainer_id,
                session_id,
                transaction_type,
                delta_credits,
                balance_after,
                reason,
                created_by
            ) VALUES (
                v_client_pkg.id,
                v_session.client_id,
                v_session.trainer_id,
                p_session_id,
                'CANCELLATION_PENALTY',
                -COALESCE(v_trainer.late_cancellation_penalty_credits, 1),
                v_new_balance,
                'Late cancellation penalty (< ' || COALESCE(v_trainer.cancellation_grace_hours, 4) || 'h window)',
                p_cancelled_by
            );
        END IF;
    END IF;

    UPDATE sessions
    SET status = 'CANCELLED',
        cancellation_reason = p_reason,
        cancelled_by = p_cancelled_by,
        cancelled_at = NOW(),
        updated_at = NOW()
    WHERE id = p_session_id;

    RETURN jsonb_build_object(
        'success', true,
        'penalty_applied', v_penalty_applied,
        'hours_before_start', v_hours_until_start,
        'new_balance', v_new_balance
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4. REASSIGN CLIENT (HEAD TRAINER / GYM MANAGER CONSOLE)
CREATE OR REPLACE FUNCTION reassign_client(
    p_relationship_id UUID,
    p_from_trainer_id UUID,
    p_to_trainer_id UUID,
    p_reason TEXT,
    p_reassigned_by UUID
)
RETURNS JSONB AS $$
DECLARE
    v_rel RECORD;
BEGIN
    SELECT * INTO v_rel
    FROM relationships
    WHERE id = p_relationship_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Relationship % not found', p_relationship_id;
    END IF;

    -- 1. Update relationship record
    UPDATE relationships
    SET trainer_id = p_to_trainer_id,
        reassigned_from_trainer_id = p_from_trainer_id,
        reassigned_at = NOW(),
        reassignment_reason = p_reason,
        status = 'REASSIGNED',
        updated_at = NOW()
    WHERE id = p_relationship_id;

    -- 2. Update active packages to point to new coach, preserving 100% of credits
    UPDATE client_packages
    SET trainer_id = p_to_trainer_id,
        updated_at = NOW()
    WHERE client_id = v_rel.client_id
      AND trainer_id = p_from_trainer_id;

    -- 3. Record transfer audit log in credit ledger
    INSERT INTO credit_ledger_transactions (
        client_package_id,
        client_id,
        trainer_id,
        transaction_type,
        delta_credits,
        balance_after,
        reason,
        created_by
    )
    SELECT 
        id,
        client_id,
        p_to_trainer_id,
        'CLIENT_TRANSFER',
        0,
        remaining_sessions,
        'Coach reassigned from ' || p_from_trainer_id || ' to ' || p_to_trainer_id || '. History & credits preserved.',
        p_reassigned_by
    FROM client_packages
    WHERE client_id = v_rel.client_id
      AND status = 'ACTIVE';

    -- 4. Notifications
    INSERT INTO notifications (user_id, title, message, type)
    VALUES (
        v_rel.client_id,
        'Coach Reassignment Notice 🔄',
        'You have been transitioned to your new coach. All your active package credits, workout history, and progress logs are preserved.',
        'REASSIGNMENT'
    );

    RETURN jsonb_build_object('success', true, 'client_id', v_rel.client_id, 'new_trainer_id', p_to_trainer_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
