import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';

import { ApiHttpService } from '../../../core/http/api-http.service';
import { API_BASE_URL } from '../../../core/tokens/api-base-url.token';
import { HttmFacilityService } from './httm-facility.service';

describe('HttmFacilityService', () => {
  let service: HttmFacilityService;
  let http: HttpTestingController;

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        HttmFacilityService,
        ApiHttpService,
        provideHttpClient(),
        provideHttpClientTesting(),
        { provide: API_BASE_URL, useValue: 'http://localhost:5999' },
      ],
    });
    service = TestBed.inject(HttmFacilityService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => {
    http.verify();
  });

  it('search sends GET with page and pageSize', (done) => {
    service.search({ page: 2, pageSize: 15 }).subscribe((res) => {
      expect(res.totalCount).toBe(0);
      expect(res.items).toEqual([]);
      done();
    });

    const req = http.expectOne((r) => r.url === 'http://localhost:5999/api/httm');
    expect(req.request.method).toBe('GET');
    expect(req.request.params.get('page')).toBe('2');
    expect(req.request.params.get('pageSize')).toBe('15');
    req.flush({ totalCount: 0, items: [] });
  });
});
