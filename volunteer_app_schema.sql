-- Volunteer Matching App Schema
-- Generated on 2026-05-07

BEGIN;

-- Optional geospatial support
CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE volunteer (
    id SERIAL PRIMARY KEY,
    full_name TEXT NOT NULL,
    contact_email TEXT UNIQUE NOT NULL,
    phone TEXT,
    home_geohash TEXT,
    preferred_radius_km NUMERIC(5,2) DEFAULT 10.0,
    consent_data_share BOOLEAN DEFAULT FALSE,
    disability_notes TEXT,
    is_adult_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE volunteer_preference (
    id SERIAL PRIMARY KEY,
    volunteer_id INTEGER NOT NULL REFERENCES volunteer(id) ON DELETE CASCADE,
    activity_type TEXT,
    weekday_mask BIT(7),
    max_distance_km NUMERIC(5,2),
    notification_channel TEXT CHECK (notification_channel IN ('email','sms','push'))
);

CREATE TABLE organiser (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    organisation_name TEXT,
    contact_email TEXT UNIQUE NOT NULL,
    phone TEXT,
    verification_status TEXT NOT NULL CHECK (verification_status IN ('pending','verified','suspended')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE organiser_channel (
    id SERIAL PRIMARY KEY,
    organiser_id INTEGER NOT NULL REFERENCES organiser(id) ON DELETE CASCADE,
    channel_type TEXT NOT NULL,
    url_or_handle TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE
);

CREATE TYPE event_status AS ENUM ('draft','pending_review','approved','cancelled');
CREATE TYPE weather_dependency AS ENUM ('none','light','critical');
CREATE TYPE update_type AS ENUM ('note','cancellation','reschedule');
CREATE TYPE skill_level AS ENUM ('beginner','intermediate','advanced');
CREATE TYPE skill_requirement AS ENUM ('optional','preferred','required');
CREATE TYPE rsvp_status AS ENUM ('interested','going','maybe','cancelled');
CREATE TYPE notification_status AS ENUM ('queued','sending','sent','failed');
CREATE TYPE moderation_status AS ENUM ('pending','approved','rejected');
CREATE TYPE account_type AS ENUM ('volunteer','organiser');
CREATE TYPE campaign_status AS ENUM ('draft','approved','paused','expired');
CREATE TYPE advertiser_status AS ENUM ('pending','active','suspended');
CREATE TYPE entity_type AS ENUM ('event','organiser','volunteer');

CREATE TABLE event (
    id SERIAL PRIMARY KEY,
    organiser_id INTEGER NOT NULL REFERENCES organiser(id),
    title TEXT NOT NULL,
    description TEXT,
    activity_type TEXT NOT NULL,
    is_invite_only BOOLEAN DEFAULT FALSE,
    location_lat NUMERIC(9,6),
    location_lng NUMERIC(9,6),
    location_precision_m INTEGER DEFAULT 200 CHECK (location_precision_m >= 0),
    excludes_children_animals BOOLEAN DEFAULT TRUE,
    status event_status NOT NULL DEFAULT 'pending_review',
    coords GEOGRAPHY(Point, 4326),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE event_requirement (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES event(id) ON DELETE CASCADE,
    item_description TEXT NOT NULL,
    quantity INTEGER,
    notes TEXT
);

CREATE TABLE event_schedule (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES event(id) ON DELETE CASCADE,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    expected_duration_minutes INTEGER,
    weather_dependency weather_dependency,
    recurrence_rule TEXT,
    capacity_target INTEGER,
    CHECK (end_at IS NULL OR end_at >= start_at)
);

CREATE TABLE event_update (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES event(id) ON DELETE CASCADE,
    organiser_id INTEGER NOT NULL REFERENCES organiser(id),
    update_type update_type NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE event_skill (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES event(id) ON DELETE CASCADE,
    skill_tag TEXT NOT NULL,
    required_level skill_requirement NOT NULL DEFAULT 'optional'
);

CREATE TABLE volunteer_skill (
    id SERIAL PRIMARY KEY,
    volunteer_id INTEGER NOT NULL REFERENCES volunteer(id) ON DELETE CASCADE,
    skill_tag TEXT NOT NULL,
    skill_level skill_level,
    last_verified_at TIMESTAMPTZ,
    UNIQUE (volunteer_id, skill_tag)
);

CREATE TABLE attendance_intent (
    id SERIAL PRIMARY KEY,
    volunteer_id INTEGER NOT NULL REFERENCES volunteer(id) ON DELETE CASCADE,
    event_schedule_id INTEGER NOT NULL REFERENCES event_schedule(id) ON DELETE CASCADE,
    rsvp_status rsvp_status NOT NULL,
    party_size INTEGER DEFAULT 1 CHECK (party_size > 0),
    response_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (volunteer_id, event_schedule_id)
);

CREATE TABLE attendance_record (
    id SERIAL PRIMARY KEY,
    volunteer_id INTEGER NOT NULL REFERENCES volunteer(id) ON DELETE CASCADE,
    event_schedule_id INTEGER NOT NULL REFERENCES event_schedule(id) ON DELETE CASCADE,
    attended BOOLEAN,
    check_in_at TIMESTAMPTZ,
    notes TEXT,
    UNIQUE (volunteer_id, event_schedule_id)
);

CREATE TABLE notification (
    id SERIAL PRIMARY KEY,
    recipient_type account_type NOT NULL,
    recipient_id INTEGER NOT NULL,
    event_schedule_id INTEGER REFERENCES event_schedule(id) ON DELETE SET NULL,
    notification_type TEXT NOT NULL,
    payload JSONB,
    status notification_status NOT NULL DEFAULT 'queued',
    scheduled_for TIMESTAMPTZ,
    sent_at TIMESTAMPTZ
);

CREATE TABLE moderation_case (
    id SERIAL PRIMARY KEY,
    entity_type entity_type NOT NULL,
    entity_id INTEGER NOT NULL,
    status moderation_status NOT NULL DEFAULT 'pending',
    moderator_id INTEGER,
    submitted_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT
);

CREATE TABLE advertiser (
    id SERIAL PRIMARY KEY,
    organisation_name TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    status advertiser_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ad_campaign (
    id SERIAL PRIMARY KEY,
    advertiser_id INTEGER NOT NULL REFERENCES advertiser(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    target_postcode_prefix TEXT,
    target_radius_km NUMERIC(5,2),
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ,
    max_impressions INTEGER,
    landing_url TEXT,
    creative_summary TEXT,
    status campaign_status NOT NULL DEFAULT 'draft',
    CHECK (end_at IS NULL OR end_at >= start_at)
);

CREATE TABLE ad_impression (
    id SERIAL PRIMARY KEY,
    campaign_id INTEGER NOT NULL REFERENCES ad_campaign(id) ON DELETE CASCADE,
    volunteer_id INTEGER REFERENCES volunteer(id) ON DELETE SET NULL,
    event_schedule_id INTEGER REFERENCES event_schedule(id) ON DELETE SET NULL,
    shown_at TIMESTAMPTZ DEFAULT NOW(),
    clicked BOOLEAN DEFAULT FALSE
);

-- Supporting indexes
CREATE INDEX idx_volunteer_email ON volunteer (contact_email);
CREATE INDEX idx_event_activity ON event (activity_type);
CREATE INDEX idx_event_status ON event (status);
CREATE INDEX idx_event_coords ON event USING GIST (coords);
CREATE INDEX idx_event_schedule_start ON event_schedule (start_at);
CREATE INDEX idx_attendance_intent_rsvp ON attendance_intent (rsvp_status);
CREATE INDEX idx_notification_status ON notification (status, scheduled_for);
CREATE INDEX idx_moderation_status ON moderation_case (status, submitted_at);
CREATE INDEX idx_ad_campaign_status ON ad_campaign (status, start_at);

COMMIT;
