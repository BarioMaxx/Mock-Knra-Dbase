import React, { useEffect, useMemo, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, BadgeCheck, Building2, CalendarClock, CreditCard, Search } from 'lucide-react';
import './styles.css';

const sampleRecords = {
  facilities: [
    {
      id: 1,
      hospital_name: 'Kenyatta National Hospital',
      location: 'Nairobi',
      facility_class: 'Class II',
      equipment_classes: ['CT Scanner', 'X-ray', 'Radiotherapy'],
      status: 'active'
    },
    {
      id: 2,
      hospital_name: 'Aga Khan University Hospital',
      location: 'Nairobi',
      facility_class: 'Class I',
      equipment_classes: ['Radiotherapy', 'Nuclear Medicine', 'Diagnostic Imaging'],
      status: 'active'
    },
    {
      id: 3,
      hospital_name: 'Mombasa Hospital',
      location: 'Mombasa',
      facility_class: 'Class III',
      equipment_classes: ['X-ray', 'CT Scanner'],
      status: 'active'
    }
  ],
  licenses: [
    {
      id: 1,
      license_number: 'KNRA-2023-000001',
      hospital_name: 'Kenyatta National Hospital',
      issue_date: '2023-01-15',
      expiry_date: '2027-01-14',
      status: 'active',
      fee_paid: true,
      fee_amount: 250000
    },
    {
      id: 2,
      license_number: 'KNRA-2024-000015',
      hospital_name: 'Aga Khan University Hospital',
      issue_date: '2024-02-01',
      expiry_date: '2028-01-31',
      status: 'active',
      fee_paid: true,
      fee_amount: 350000
    }
  ],
  source: 'sample'
};

function formatDate(value) {
  if (!value) return 'Not set';
  return new Intl.DateTimeFormat('en-KE', {
    year: 'numeric',
    month: 'short',
    day: '2-digit'
  }).format(new Date(value));
}

function formatCurrency(value) {
  return new Intl.NumberFormat('en-KE', {
    style: 'currency',
    currency: 'KES',
    maximumFractionDigits: 0
  }).format(Number(value || 0));
}

function normalizeEquipment(value) {
  if (Array.isArray(value)) return value;
  if (!value) return [];

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function App() {
  const [records, setRecords] = useState(sampleRecords);
  const [query, setQuery] = useState('');
  const [notice, setNotice] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    async function loadRecords() {
      try {
        const response = await fetch('/api/dashboard-records');
        if (!response.ok) throw new Error('Records endpoint unavailable');
        const data = await response.json();

        if (isMounted) {
          setRecords(data);
          setNotice(data.notice || '');
        }
      } catch {
        if (isMounted) {
          setRecords(sampleRecords);
          setNotice('Showing sample records while the database connection is unavailable.');
        }
      } finally {
        if (isMounted) setIsLoading(false);
      }
    }

    loadRecords();
    return () => {
      isMounted = false;
    };
  }, []);

  const facilities = records.facilities || [];
  const licenses = records.licenses || [];

  const filteredFacilities = useMemo(() => {
    const term = query.trim().toLowerCase();
    if (!term) return facilities;

    return facilities.filter((facility) => {
      const equipment = normalizeEquipment(facility.equipment_classes).join(' ');
      return `${facility.hospital_name} ${facility.location} ${facility.facility_class} ${equipment}`
        .toLowerCase()
        .includes(term);
    });
  }, [facilities, query]);

  const filteredLicenses = useMemo(() => {
    const term = query.trim().toLowerCase();
    if (!term) return licenses;

    return licenses.filter((license) =>
      `${license.license_number} ${license.hospital_name} ${license.status}`
        .toLowerCase()
        .includes(term)
    );
  }, [licenses, query]);

  const paidLicenses = licenses.filter((license) => Boolean(license.fee_paid)).length;
  const activeLicenses = licenses.filter((license) => license.status === 'active').length;

  return (
    <main className="app-shell">
      <section className="hero-band">
        <div>
          <p className="eyebrow">Radiation facility licensing</p>
          <h1>KNRA Records Dashboard</h1>
          <p className="hero-copy">
            A simple operating view for hospital facilities, radiation equipment classes,
            license validity, and payment status.
          </p>
        </div>

        <div className="hero-actions">
          <label className="search-box" htmlFor="record-search">
            <Search size={18} aria-hidden="true" />
            <input
              id="record-search"
              type="search"
              placeholder="Search records"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
            />
          </label>
          <span className={`source-pill ${records.source === 'database' ? 'live' : ''}`}>
            {isLoading ? 'Loading' : records.source === 'database' ? 'Live database' : 'Sample data'}
          </span>
        </div>
      </section>

      {notice ? <p className="notice">{notice}</p> : null}

      <section className="metric-grid" aria-label="Record summary">
        <Metric icon={Building2} label="Facilities" value={facilities.length} />
        <Metric icon={BadgeCheck} label="Active licenses" value={activeLicenses} />
        <Metric icon={CreditCard} label="Fees paid" value={`${paidLicenses}/${licenses.length}`} />
        <Metric icon={Activity} label="Tracked classes" value={new Set(facilities.map((item) => item.facility_class)).size} />
      </section>

      <section className="records-layout">
        <RecordsPanel title="Facilities" icon={Building2}>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Hospital name</th>
                  <th>Location</th>
                  <th>Class of radiation equipment</th>
                  <th>Equipment</th>
                </tr>
              </thead>
              <tbody>
                {filteredFacilities.map((facility) => (
                  <tr key={facility.id}>
                    <td>
                      <strong>{facility.hospital_name}</strong>
                      <span>{facility.status}</span>
                    </td>
                    <td>{facility.location}</td>
                    <td>
                      <span className="status-badge class-badge">{facility.facility_class}</span>
                    </td>
                    <td>
                      <div className="chip-list">
                        {normalizeEquipment(facility.equipment_classes).map((equipment) => (
                          <span className="chip" key={`${facility.id}-${equipment}`}>{equipment}</span>
                        ))}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </RecordsPanel>

        <RecordsPanel title="Licenses" icon={CalendarClock}>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Facility</th>
                  <th>Issue date</th>
                  <th>Expiry date</th>
                  <th>Status</th>
                  <th>Fee paid</th>
                </tr>
              </thead>
              <tbody>
                {filteredLicenses.map((license) => (
                  <tr key={license.id}>
                    <td>
                      <strong>{license.hospital_name}</strong>
                      <span>{license.license_number}</span>
                    </td>
                    <td>{formatDate(license.issue_date)}</td>
                    <td>{formatDate(license.expiry_date)}</td>
                    <td>
                      <span className={`status-badge ${license.status}`}>{license.status}</span>
                    </td>
                    <td>
                      <strong>{license.fee_paid ? 'Paid' : 'Unpaid'}</strong>
                      <span>{formatCurrency(license.fee_amount)}</span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </RecordsPanel>
      </section>
    </main>
  );
}

function Metric({ icon: Icon, label, value }) {
  return (
    <article className="metric-card">
      <div className="metric-icon">
        <Icon size={20} aria-hidden="true" />
      </div>
      <div>
        <p>{label}</p>
        <strong>{value}</strong>
      </div>
    </article>
  );
}

function RecordsPanel({ title, icon: Icon, children }) {
  return (
    <section className="records-panel">
      <header>
        <Icon size={20} aria-hidden="true" />
        <h2>{title}</h2>
      </header>
      {children}
    </section>
  );
}

createRoot(document.getElementById('root')).render(<App />);
