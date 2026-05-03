/** Subset of RFC 7807 / ASP.NET Core ProblemDetails returned on 400 responses. */
export interface ApiProblemDetails {
  type?: string | null;
  title?: string | null;
  status?: number | null;
  detail?: string | null;
  instance?: string | null;
}
